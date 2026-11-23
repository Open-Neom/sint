/// Indicates status of snackbar:
/// [SnackbarStatus.open] Snack is fully open,
/// [SnackbarStatus.closed] Snackbar has closed,
/// [SnackbarStatus.opening] Starts with the opening animation and ends
/// with the full snackbar display,
/// [SnackbarStatus.closing] Starts with the closing animation and ends
/// with the full snackbar dispose.
enum SnackbarStatus { open, closed, opening, closing }
