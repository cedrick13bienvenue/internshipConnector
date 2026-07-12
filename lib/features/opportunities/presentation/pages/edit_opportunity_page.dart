import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/opportunity_model.dart';
import '../../data/repositories/opportunity_repository.dart';

class EditOpportunityPage extends StatefulWidget {
  final OpportunityModel opportunity;
  const EditOpportunityPage({super.key, required this.opportunity});

  @override
  State<EditOpportunityPage> createState() => _EditOpportunityPageState();
}

class _EditOpportunityPageState extends State<EditOpportunityPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late String _category;
  late String _commitment;
  late String _location;
  final Set<String> _selectedSkills = {};
  final TextEditingController _customSkillController = TextEditingController();
  DateTime? _deadline;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final opp = widget.opportunity;
    _titleController = TextEditingController(text: opp.title);
    _descController = TextEditingController(text: opp.description);
    _category = opp.category;
    _commitment = opp.commitment;
    _location = opp.location;
    _selectedSkills.addAll(opp.skillsRequired);
    _deadline = opp.deadline;
  }

  Set<String> get _customSkills =>
      _selectedSkills.where((s) => !AppConstants.skills.contains(s)).toSet();

  void _addCustomSkill() {
    final skill = _customSkillController.text.trim();
    if (skill.isEmpty || _selectedSkills.contains(skill)) return;
    setState(() {
      _selectedSkills.add(skill);
      _customSkillController.clear();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _customSkillController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final opp = widget.opportunity;
      final updated = OpportunityModel(
        id: opp.id,
        startupId: opp.startupId,
        startupName: opp.startupName,
        startupLogoUrl: opp.startupLogoUrl,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _category,
        commitment: _commitment,
        location: _location,
        skillsRequired: _selectedSkills.toList(),
        postedAt: opp.postedAt,
        deadline: _deadline,
        status: opp.status,
        applicantsCount: opp.applicantsCount,
      );
      await OpportunityRepository().update(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opportunity updated.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _closeOpportunity() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close Opportunity'),
        content: const Text(
            'This stops new applications from being submitted. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Close It'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await OpportunityRepository().close(widget.opportunity.id);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Opportunity'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _closeOpportunity,
            child: const Text('Close', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: AppConstants.opportunityCategories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _commitment,
            decoration: const InputDecoration(labelText: 'Commitment'),
            items: AppConstants.commitmentTypes
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _commitment = v!),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _location,
            decoration: const InputDecoration(labelText: 'Location'),
            items: AppConstants.locationTypes
                .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                .toList(),
            onChanged: (v) => setState(() => _location = v!),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _descController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Description',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
          Text('Required Skills', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.skills.map((s) {
              final selected = _selectedSkills.contains(s);
              return FilterChip(
                label: Text(s),
                selected: selected,
                onSelected: (v) =>
                    setState(() => v ? _selectedSkills.add(s) : _selectedSkills.remove(s)),
                selectedColor: AppColors.primaryLight,
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontSize: 12,
                ),
                side: BorderSide(color: selected ? AppColors.primary : AppColors.divider),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customSkillController,
                  decoration: InputDecoration(
                    hintText: 'Add other skill...',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => _addCustomSkill(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _addCustomSkill,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          if (_customSkills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _customSkills.map((s) => Chip(
                label: Text(s, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                deleteIcon: const Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
                onDeleted: () => setState(() => _selectedSkills.remove(s)),
                backgroundColor: AppColors.primaryLight,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              )).toList(),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDeadline,
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text(_deadline == null
                      ? 'Add Deadline'
                      : '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'),
                ),
              ),
              if (_deadline != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => setState(() => _deadline = null),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: AppColors.error,
                  tooltip: 'Remove deadline',
                ),
              ],
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save Changes'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
