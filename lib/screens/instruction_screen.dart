import 'package:flutter/material.dart';
import '../theme/app_color_locker.dart';

class InstructionScreen extends StatelessWidget {
  const InstructionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locker = AppColorLocker.of(context);
    return Scaffold(
      backgroundColor: locker.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: locker.scaffoldBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: locker.textPrimary),
        title: Text(
          'INSTRUCTION',
          style: TextStyle(
            color: locker.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontFamily: 'MonumentExtended',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Section 1
          Text(
            '1. Ghi chép thu chi',
            style: TextStyle(
              color: locker.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhấn nút "+" ở góc dưới màn hình Home để thêm một giao dịch mới. '
            'Chọn loại thu nhập hoặc chi tiêu, nhập số tiền và danh mục tương ứng. '
            'Tất cả giao dịch sẽ được lưu lại và hiển thị ngay trên màn hình chính.',
            style: TextStyle(color: locker.textPrimary.withValues(alpha: 0.87), fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 32),

          // Section 2
          Text(
            '2. Đọc biểu đồ dòng tiền',
            style: TextStyle(
              color: locker.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Theo dõi biểu đồ dòng tiền để nắm bắt tổng quan tình hình tài chính. '
            'Biểu đồ hiển thị thu nhập và chi tiêu theo từng khoảng thời gian, '
            'giúp bạn dễ dàng nhận biết xu hướng chi tiêu của bản thân.',
            style: TextStyle(color: locker.textPrimary.withValues(alpha: 0.87), fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 32),

          // Section 3
          Text(
            '3. Phân tích tài chính',
            style: TextStyle(
              color: locker.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Xem báo cáo phân tích chi tiết theo từng danh mục chi tiêu. '
            'Ứng dụng sẽ tổng hợp và hiển thị tỷ lệ phần trăm chi tiêu của từng '
            'nhóm như ăn uống, di chuyển, mua sắm,... giúp bạn tối ưu hóa ngân sách.',
            style: TextStyle(color: locker.textPrimary.withValues(alpha: 0.87), fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }
}
