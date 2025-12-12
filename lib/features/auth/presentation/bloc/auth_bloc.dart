import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SupabaseClient _supabase;

  AuthBloc({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client,
      super(
        (supabase ?? Supabase.instance.client).auth.currentSession != null
            ? AuthAuthenticated(
                (supabase ?? Supabase.instance.client).auth.currentSession!,
              )
            : AuthInitial(),
      ) {
    on<AuthSignInWithEmail>(_onSignInWithEmail);
    on<AuthSignUpWithEmail>(_onSignUpWithEmail);
    on<AuthSignInWithGoogle>(_onSignInWithGoogle);
    on<AuthSignInWithGithub>(_onSignInWithGithub);
    on<AuthSignOut>(_onSignOut);
  }

  Future<void> _onSignInWithEmail(
    AuthSignInWithEmail event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: event.email,
        password: event.password,
      );
      if (response.session != null) {
        emit(AuthAuthenticated(response.session!));
      } else {
        emit(const AuthError('Sign in failed: No session created.'));
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('Unexpected error: $e'));
    }
  }

  Future<void> _onSignUpWithEmail(
    AuthSignUpWithEmail event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await _supabase.auth.signUp(
        email: event.email,
        password: event.password,
      );
      if (response.session != null) {
        emit(AuthAuthenticated(response.session!));
      } else {
        emit(const AuthError('Please check your email for confirmation.'));
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('Unexpected error: $e'));
    }
  }

  Future<void> _onSignInWithGoogle(
    AuthSignInWithGoogle event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      /// Web Client ID that you registered with Google Cloud.
      const webClientId =
          '805163956327-u6suvcl5gh86n8qbak175amnloe7rdjr.apps.googleusercontent.com';

      /// iOS Client ID that you registered with Google Cloud.
      const iosClientId =
          '805163956327-gvr31r03mpmqd5cn8frfcvbirsd0kj9f.apps.googleusercontent.com';

      final scopes = ['email', 'profile'];
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        serverClientId: webClientId,
        clientId: iosClientId,
      );
      final googleUser = await googleSignIn.attemptLightweightAuthentication();
      // or await googleSignIn.authenticate(); which will return a GoogleSignInAccount or throw an exception
      if (googleUser == null) {
        throw AuthException('Failed to sign in with Google.');
      }

      /// Authorization is required to obtain the access token with the appropriate scopes for Supabase authentication,
      /// while also granting permission to access user information.
      final authorization =
          await googleUser.authorizationClient.authorizationForScopes(scopes) ??
          await googleUser.authorizationClient.authorizeScopes(scopes);
      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw AuthException('No ID Token found.');
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: authorization.accessToken,
      );

      if (response.session != null) {
        emit(AuthAuthenticated(response.session!));
      } else {
        emit(const AuthError('Google Sign In failed: No session created.'));
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('Unexpected error: $e'));
    }
  }

  Future<void> _onSignInWithGithub(
    AuthSignInWithGithub event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.github,
        redirectTo: 'io.supabase.flutterquickstart://login-callback/',
      );
      final session = _supabase.auth.currentSession;
      if (session != null) {
        emit(AuthAuthenticated(session));
      } else {
        emit(const AuthError('Sign in failed: No session created.'));
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('Unexpected error: $e'));
    }
  }

  Future<void> _onSignOut(AuthSignOut event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _supabase.auth.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Sign out failed: $e'));
    }
  }
}
