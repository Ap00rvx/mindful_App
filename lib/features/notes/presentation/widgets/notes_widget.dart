import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindful_app/features/notes/presentation/widgets/add_note_bottom_sheet.dart';
import 'package:mindful_app/theme/app_colors.dart';
import 'package:shimmer/shimmer.dart';
import '../bloc/note_bloc.dart';
import '../bloc/note_event.dart';
import '../bloc/note_state.dart';

class NotesWidget extends StatefulWidget {
  const NotesWidget({super.key});

  @override
  State<NotesWidget> createState() => _NotesWidgetState();
}

class _NotesWidgetState extends State<NotesWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<NoteBloc>().add(LoadNotes());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Text(
                "Saved Notes",
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        BlocBuilder<NoteBloc, NoteState>(
          builder: (context, state) {
            if (state is NotesLoading) {
              return SizedBox(
                height: 300,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(3, (index) {
                      return Shimmer.fromColors(
                        baseColor: Colors.white.withOpacity(0.1),
                        highlightColor: Colors.white.withOpacity(0.05),
                        child: Container(
                          margin: const EdgeInsets.all(8.0),
                          width: 200,
                          height: 260,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white60),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              );
            } else if (state is NotesLoaded) {
              return Container(
                height: 300,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(state.notes.length + 1, (index) {
                      final sortedNotes = List.from(state.notes)
                        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                      if (index == 0) {
                        return GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) => BlocProvider.value(
                                value: context.read<NoteBloc>(),
                                child: const AddNoteBottomSheet(),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.all(8.0),
                            padding: const EdgeInsets.all(12.0),
                            width: 200,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white60),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            height: 260,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add,
                                  color: Colors.white70,
                                  size: 50,
                                ),
                                Text(
                                  "Add Note",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return Container(
                        margin: const EdgeInsets.all(8.0),
                        padding: const EdgeInsets.all(12.0),
                        width: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white60),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        height: 260,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              sortedNotes[index - 1].content.length > 60
                                  ? '${sortedNotes[index - 1].content.substring(0, 60)}...'
                                  : sortedNotes[index - 1].content,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${sortedNotes[index - 1].createdAt.day}/${sortedNotes[index - 1].createdAt.month}/${sortedNotes[index - 1].createdAt.year}",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Image.asset(
                                  "assets/images/arrow.png",
                                  width: 20,
                                  height: 20,
                                  color: Colors.white70,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              );
            } else if (state is NotesError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            return const SizedBox.shrink();
          },
        ),
        SizedBox(height: 20),
      ],
    );
  }
}
