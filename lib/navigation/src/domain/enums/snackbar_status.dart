/// Indicates Status of snackbar
/// [SnackbarStatus.OPEN] Snack is fully open, [SnackbarStatus.CLOSED] Snackbar
/// has closed,
/// [SnackbarStatus.OPENING] Starts with the opening animation and ends
/// with the full
/// snackbar display, [SnackbarStatus.CLOSING] Starts with the closing animation
/// and ends
/// with the full snackbar dispose
enum SnackbarStatus {
  open,
  closed,
  opening,
  closing
}
