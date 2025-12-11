import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mindful_app/core/widget/dyno_bg.dart';
import 'package:mindful_app/features/home/presentation/widgets/searchbar.dart';
import 'package:mindful_app/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const DynoBg(left: 240, right: 260),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  floating: true,
                  snap: true,
                  toolbarHeight: 100,

                  leading: GestureDetector(
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(Icons.menu),
                      ),
                    ),
                  ),
                  actions: [
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
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
