import 'package:flutter/material.dart';

enum CatEventType {
  litterScoop,
  litterChange,
  waterChange,
  vomit,
  hairball,
  deworming,
  fleaTreatment,
  feeding,
  playtime,
  note,
}

extension CatEventTypeX on CatEventType {
  String get storageKey {
    switch (this) {
      case CatEventType.litterScoop:
        return 'litter_scoop';
      case CatEventType.litterChange:
        return 'litter_change';
      case CatEventType.waterChange:
        return 'water_change';
      case CatEventType.vomit:
        return 'vomit';
      case CatEventType.hairball:
        return 'hairball';
      case CatEventType.deworming:
        return 'deworming';
      case CatEventType.fleaTreatment:
        return 'flea_treatment';
      case CatEventType.feeding:
        return 'feeding';
      case CatEventType.playtime:
        return 'playtime';
      case CatEventType.note:
        return 'note';
    }
  }

  String get label {
    switch (this) {
      case CatEventType.litterScoop:
        return 'Litter Scooped';
      case CatEventType.litterChange:
        return 'Litter Changed';
      case CatEventType.waterChange:
        return 'Water Changed';
      case CatEventType.vomit:
        return 'Vomiting';
      case CatEventType.hairball:
        return 'Hairball';
      case CatEventType.deworming:
        return 'Deworming';
      case CatEventType.fleaTreatment:
        return 'Flea/Tick Treatment';
      case CatEventType.feeding:
        return 'Feeding';
      case CatEventType.playtime:
        return 'Playtime';
      case CatEventType.note:
        return 'General Note';
    }
  }

  IconData get icon {
    switch (this) {
      case CatEventType.litterScoop:
        return Icons.cleaning_services;
      case CatEventType.litterChange:
        return Icons.delete_sweep;
      case CatEventType.waterChange:
        return Icons.water_drop;
      case CatEventType.vomit:
        return Icons.sick;
      case CatEventType.hairball:
        return Icons.healing;
      case CatEventType.deworming:
        return Icons.medication;
      case CatEventType.fleaTreatment:
        return Icons.bug_report;
      case CatEventType.feeding:
        return Icons.restaurant;
      case CatEventType.playtime:
        return Icons.toys;
      case CatEventType.note:
        return Icons.notes;
    }
  }

  static CatEventType fromStorageKey(String key) {
    return CatEventType.values.firstWhere(
      (e) => e.storageKey == key,
      orElse: () => CatEventType.note,
    );
  }
}
