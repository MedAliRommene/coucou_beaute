import 'user.dart';
import 'service.dart';

enum AppointmentStatus {
  pending,      // En attente
  confirmed,    // Confirmé
  completed,    // Terminé
  cancelled,    // Annulé
  noShow        // Absent
}

class Appointment {
  final int id;
  final int clientId;
  final int professionalId;
  final int serviceId;
  final DateTime appointmentDate;
  final String appointmentTime;
  final AppointmentStatus status;
  final DateTime createdAt;
  final String? notes;
  final double totalPrice;
  
  // Relations (optionnelles pour éviter les requêtes circulaires)
  final User? client;
  final User? professional;
  final Service? service;

  Appointment({
    required this.id,
    required this.clientId,
    required this.professionalId,
    required this.serviceId,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.status,
    required this.createdAt,
    this.notes,
    required this.totalPrice,
    this.client,
    this.professional,
    this.service,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      clientId: json['client_id'],
      professionalId: json['professional_id'],
      serviceId: json['service_id'],
      appointmentDate: DateTime.parse(json['appointment_date']),
      appointmentTime: json['appointment_time'],
      status: AppointmentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => AppointmentStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at']),
      notes: json['notes'],
      totalPrice: json['total_price'].toDouble(),
      client: json['client'] != null ? User.fromJson(json['client']) : null,
      professional: json['professional'] != null ? User.fromJson(json['professional']) : null,
      service: json['service'] != null ? Service.fromJson(json['service']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'professional_id': professionalId,
      'service_id': serviceId,
      'appointment_date': appointmentDate.toIso8601String(),
      'appointment_time': appointmentTime,
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'notes': notes,
      'total_price': totalPrice,
      'client': client?.toJson(),
      'professional': professional?.toJson(),
      'service': service?.toJson(),
    };
  }

  String get statusLabel {
    switch (status) {
      case AppointmentStatus.pending:
        return 'En attente';
      case AppointmentStatus.confirmed:
        return 'Confirmé';
      case AppointmentStatus.completed:
        return 'Terminé';
      case AppointmentStatus.cancelled:
        return 'Annulé';
      case AppointmentStatus.noShow:
        return 'Absent';
    }
  }

  bool get isUpcoming => 
      appointmentDate.isAfter(DateTime.now()) && 
      status == AppointmentStatus.confirmed;

  bool get isToday => 
      appointmentDate.year == DateTime.now().year &&
      appointmentDate.month == DateTime.now().month &&
      appointmentDate.day == DateTime.now().day;
}
