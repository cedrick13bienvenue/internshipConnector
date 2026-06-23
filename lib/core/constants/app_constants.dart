class AppConstants {
  static const List<String> opportunityCategories = [
    'Design',
    'Engineering',
    'Marketing',
    'Data',
    'Operations',
    'Research',
    'Business',
    'Content',
    'Community',
    'Other',
  ];

  static const List<String> commitmentTypes = [
    'Part-time (4–6 hrs/week)',
    'Part-time (8–10 hrs/week)',
    'Full-time',
    'Project-based',
  ];

  static const List<String> locationTypes = [
    'Remote',
    'On-campus',
    'Hybrid',
  ];

  static const int maxApplicationsPerUser = 10;
  static const int maxOpportunitiesPerStartup = 20;
  static const int searchDebounceMs = 400;
}
