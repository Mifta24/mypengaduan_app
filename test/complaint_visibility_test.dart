import 'package:flutter_test/flutter_test.dart';
import 'package:mypengaduan_app/models/complaint_model.dart';

void main() {
  Map<String, dynamic> complaintJson() => {
        'id': 1,
        'title': 'Lampu jalan rusak',
        'description': 'Lampu jalan tidak menyala sejak kemarin.',
        'location': 'RT 05',
        'status': 'pending',
        'report_date': '2026-07-23',
        'created_at': '2026-07-23T10:00:00Z',
        'updated_at': '2026-07-23T10:00:00Z',
      };

  test('legacy complaints remain public by default', () {
    final complaint = Complaint.fromJson(complaintJson());

    expect(complaint.visibility, 'public');
    expect(complaint.isPublic, isTrue);
  });

  test('private visibility is parsed from the API', () {
    final json = complaintJson()..['visibility'] = 'private';
    final complaint = Complaint.fromJson(json);

    expect(complaint.visibilityText, 'Privat');
    expect(complaint.isPublic, isFalse);
  });
}
