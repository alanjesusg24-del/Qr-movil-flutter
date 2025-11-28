/*
 * ============================================================================
 * Project:        Order QR Mobile - Focus
 * File:           app_icons.dart
 * Author:         CETAM Development Team
 * Creation Date:  2025-11-27
 * Version:        4.0.0
 * Description:    Catálogo centralizado de íconos según estándares CETAM v4.0
 * Dependencies:   flutter/material.dart
 * Notes:          NO usar Icon(Icons.xxx) directamente - usar AppIcon
 * ============================================================================
 */

import 'package:flutter/material.dart';

/// Catálogo de nombres de íconos estandarizados CETAM v4.0
///
/// Uso: `AppIcon(name: AppIconName.NOMBRE)`
///
/// Ventajas:
/// - Consistencia visual en toda la aplicación
/// - Fácil reemplazo si cambiamos de biblioteca de íconos
/// - Autocomplete en el IDE
/// - Nombres semánticos en lugar de técnicos
class AppIconName {
  // 👤 USUARIOS Y PERFILES
  static const IconData user = Icons.person_outline;
  static const IconData userCircle = Icons.account_circle_outlined;
  static const IconData userAdd = Icons.person_add_outlined;
  static const IconData userRemove = Icons.person_remove_outlined;
  static const IconData userGroup = Icons.groups_outlined;
  static const IconData userTie = Icons.badge_outlined;

  // ✏️ ACCIONES CRUD
  static const IconData add = Icons.add;
  static const IconData create = Icons.add;
  static const IconData edit = Icons.edit_outlined;
  static const IconData delete = Icons.delete_outline;
  static const IconData view = Icons.visibility_outlined;
  static const IconData save = Icons.save_outlined;
  static const IconData cancel = Icons.close;
  static const IconData send = Icons.send_outlined;
  static const IconData download = Icons.download_outlined;
  static const IconData upload = Icons.upload_outlined;
  static const IconData search = Icons.search;
  static const IconData refresh = Icons.refresh;

  // 🔔 ESTADOS Y NOTIFICACIONES
  static const IconData success = Icons.check_circle_outline;
  static const IconData error = Icons.error_outline;
  static const IconData warning = Icons.warning_amber_outlined;
  static const IconData info = Icons.info_outline;
  static const IconData pending = Icons.schedule;
  static const IconData notification = Icons.notifications_outlined;
  static const IconData notificationOff = Icons.notifications_off_outlined;

  // 📁 ARCHIVOS Y DOCUMENTOS
  static const IconData file = Icons.insert_drive_file_outlined;
  static const IconData filePdf = Icons.picture_as_pdf_outlined;
  static const IconData fileWord = Icons.description_outlined;
  static const IconData fileExcel = Icons.grid_on_outlined;
  static const IconData fileImage = Icons.image_outlined;
  static const IconData folder = Icons.folder_outlined;
  static const IconData folderOpen = Icons.folder_open_outlined;
  static const IconData attachment = Icons.attach_file;

  // 🏠 NAVEGACIÓN
  static const IconData home = Icons.home_outlined;
  static const IconData dashboard = Icons.dashboard_outlined;
  static const IconData menu = Icons.menu;
  static const IconData back = Icons.arrow_back;
  static const IconData forward = Icons.arrow_forward;
  static const IconData up = Icons.arrow_upward;
  static const IconData down = Icons.arrow_downward;
  static const IconData close = Icons.close;
  static const IconData externalLink = Icons.open_in_new;

  // ⚙️ CONFIGURACIÓN Y PROCESOS
  static const IconData settings = Icons.settings_outlined;
  static const IconData loading = Icons.hourglass_empty;
  static const IconData process = Icons.sync;
  static const IconData sync = Icons.sync_outlined;

  // 💰 FINANZAS
  static const IconData money = Icons.attach_money;
  static const IconData coins = Icons.monetization_on_outlined;
  static const IconData card = Icons.credit_card_outlined;
  static const IconData invoice = Icons.receipt_long_outlined;
  static const IconData chartUp = Icons.trending_up;
  static const IconData chartDown = Icons.bar_chart;

  // 📧 COMUNICACIÓN
  static const IconData email = Icons.email_outlined;
  static const IconData phone = Icons.phone_outlined;
  static const IconData chat = Icons.chat_bubble_outline;
  static const IconData support = Icons.support_agent_outlined;
  static const IconData help = Icons.help_outline;

  // 📋 LISTAS Y FILTROS
  static const IconData list = Icons.list;
  static const IconData listOrdered = Icons.format_list_numbered;
  static const IconData filter = Icons.filter_list;
  static const IconData sort = Icons.sort;
  static const IconData sortUp = Icons.arrow_upward;
  static const IconData sortDown = Icons.arrow_downward;
  static const IconData checkList = Icons.checklist_outlined;

  // 🔐 SEGURIDAD
  static const IconData login = Icons.login;
  static const IconData logout = Icons.logout;
  static const IconData lock = Icons.lock_outline;
  static const IconData unlock = Icons.lock_open_outlined;
  static const IconData key = Icons.key_outlined;
  static const IconData shield = Icons.shield_outlined;

  // 📊 REPORTES
  static const IconData report = Icons.assessment_outlined;
  static const IconData reportBar = Icons.bar_chart_outlined;
  static const IconData reportPie = Icons.pie_chart_outline;
  static const IconData print = Icons.print_outlined;
  static const IconData downloadReport = Icons.file_download_outlined;

  // 🛒 ORDEN QR ESPECÍFICOS
  static const IconData qrCode = Icons.qr_code;
  static const IconData qrScan = Icons.qr_code_scanner;
  static const IconData order = Icons.receipt_long_outlined;
  static const IconData orderActive = Icons.pending_actions;
  static const IconData orderReady = Icons.check_circle;
  static const IconData orderDelivered = Icons.done_all;
  static const IconData orderCancelled = Icons.cancel_outlined;
  static const IconData business = Icons.business;
  static const IconData map = Icons.map_outlined;
  static const IconData location = Icons.location_on_outlined;
  static const IconData premium = Icons.workspace_premium_outlined;
}
