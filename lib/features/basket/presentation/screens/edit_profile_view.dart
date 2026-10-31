import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/basket_ui.dart';
import 'package:fastswipe/features/basket/presentation/widgets/glass.dart';
import 'package:fastswipe/features/basket/presentation/widgets/labeled_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// Lets an already-onboarded user change their name/email — the
/// post-signup counterpart to [SetupView], which only ever runs once.
/// Saves via `BasketCubit.saveProfileEdit`, which `PATCH`s
/// `/api/auth/profile/`.
class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final state = context.read<BasketCubit>().state;
    _nameController = TextEditingController(text: state.name);
    _emailController = TextEditingController(text: state.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final phone = context.select((BasketCubit c) => c.state.phone);
    final saving = context.select((BasketCubit c) => c.state.profileSaving);
    final formError = context.select((BasketCubit c) => c.state.profileFormError);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(BasketSpace.gutter, MediaQuery.paddingOf(context).top + BasketSpace.sm, BasketSpace.gutter, BasketSpace.md),
          decoration: darkHeaderDecoration(),
          child: Row(
            children: [
              InkWell(
                onTap: cubit.back,
                borderRadius: BorderRadius.circular(BasketRadius.pill),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Color(0xFFFFFBF2).withValues(alpha: 0.1),
                    border: Border.all(color: Color(0xFFFFFBF2).withValues(alpha: 0.14)),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.arrow_back, color: Color(0xFFFFFBF2), size: 16),
                ),
              ),
              const SizedBox(width: BasketSpace.xs),
              Text('Edit profile', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFFFFBF2))),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(BasketSpace.gutter, BasketSpace.lg, BasketSpace.gutter, BasketSpace.lg),
            children: [
              LabeledTextField(
                label: 'Full name',
                controller: _nameController,
                onChanged: cubit.setName,
                textCapitalization: TextCapitalization.words,
                hintText: 'Enter your full name (First and last name)',
              ),
              const SizedBox(height: BasketSpace.md),
              LabeledTextField(
                label: 'Email (optional)',
                controller: _emailController,
                onChanged: cubit.setEmail,
                keyboardType: TextInputType.emailAddress,
                hintText: 'Enter your email (example@gmail.com)',
              ),
              const SizedBox(height: BasketSpace.md),
              LabeledStaticField(label: 'Mobile number', value: '+91 $phone', muted: true),
              if (formError != null) ...[
                const SizedBox(height: BasketSpace.sm),
                Text(formError, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: BasketColors.error)),
              ],
            ],
          ),
        ),
        BasketBottomBar(
          child: BasketButton(
            label: 'Save changes',
            loading: saving,
            onPressed: saving ? null : cubit.saveProfileEdit,
          ),
        ),
      ],
    );
  }
}
