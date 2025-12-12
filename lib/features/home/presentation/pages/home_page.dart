import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mindful_app/core/widget/dyno_bg.dart';
import 'package:mindful_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mindful_app/features/home/presentation/widgets/chat_history_list.dart';
import 'package:mindful_app/features/home/presentation/widgets/drawer.dart';
import 'package:mindful_app/features/home/presentation/widgets/searchbar.dart';
import 'package:mindful_app/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:mindful_app/features/notes/presentation/bloc/note_bloc.dart';
import 'package:mindful_app/features/notes/presentation/widgets/notes_widget.dart';
import 'package:mindful_app/features/notes/data/datasources/note_remote_data_source.dart';
import 'package:mindful_app/features/notes/data/repositories/note_repository_impl.dart';
import 'package:mindful_app/features/notes/domain/usecases/get_notes.dart';
import 'package:mindful_app/features/notes/domain/usecases/create_note.dart';
import 'package:mindful_app/core/network/dio.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalKey drawerKey = GlobalKey<DrawerControllerState>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthBloc()),
        BlocProvider(
          create: (context) {
            final dataSource = NoteRemoteDataSourceImpl(
              dio: AppClient.dio,
              supabaseClient: Supabase.instance.client,
            );
            final repository = NoteRepositoryImpl(remoteDataSource: dataSource);
            return NoteBloc(
              getNotes: GetNotes(repository),
              createNote: CreateNote(repository),
            );
          },
        ),
      ],
      child: Scaffold(
        drawer: HomeDrawer(drawerKey: drawerKey),
        body: Stack(
          children: [
            const DynoBg(left: 240, right: 260),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    floating: false,
                    snap: false,
                    toolbarHeight: 100,
                    elevation: 0,

                    leading: Builder(
                      builder: (context) {
                        return GestureDetector(
                          onTap: () {
                            Scaffold.of(context).openDrawer();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.secondary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.menu,
                                size: 20,
                                color: AppColors.white.withAlpha(200),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    actions: [
                      CircleAvatar(
                        backgroundColor: AppColors.surface,
                        backgroundImage: NetworkImage(
                          Supabase
                                  .instance
                                  .client
                                  .auth
                                  .currentUser
                                  ?.userMetadata?['avatar_url'] ??
                              'https://www.gravatar.com/avatar/',
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {},
                        child: Text("Try Premium"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate([
                      SizedBox(height: 50),
                      Text(
                        "Create, explore, \nbe Inspired",
                        style: TextStyle(
                          height: 1,
                          letterSpacing: 0.2,
                          fontSize: 45,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 20),
                      GlobalSearchBar(),
                      SizedBox(height: 20),

                      NotesWidget(),

                      ChatHistoryList(),

                      SizedBox(height: 80), // Bottom padding
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
