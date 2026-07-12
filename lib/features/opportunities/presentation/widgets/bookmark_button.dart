import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class BookmarkButton extends StatelessWidget {
  final String opportunityId;
  const BookmarkButton({super.key, required this.opportunityId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isSaved = state is AuthAuthenticated &&
            state.user.savedOpportunities.contains(opportunityId);
        return IconButton(
          icon: Icon(
            isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: isSaved ? AppColors.primary : AppColors.textHint,
          ),
          onPressed: () => context.read<AuthCubit>().toggleSaveOpportunity(opportunityId),
        );
      },
    );
  }
}
