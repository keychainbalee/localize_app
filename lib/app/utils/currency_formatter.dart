String formatCurrency(num amount) {
  final str = amount.toStringAsFixed(0);
  final pattern = RegExp(r'\B(?=(\d{3})+(?!\d))');
  return 'Rp ' + str.replaceAllMapped(pattern, (match) => '.');
}
