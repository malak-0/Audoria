  //                     const SizedBox(height: 20),
  //                     _buildKeyPoint('Operating systems manage hardware resources'),
  //                     const SizedBox(height: 12),
  //                     _buildKeyPoint('Process management handles task scheduling'),
  //                     const SizedBox(height: 12),
  //                     _buildKeyPoint('Memory management optimizes resource usage'),
  //                     const SizedBox(height: 12),
  //                     _buildKeyPoint('File systems organize data storage'),
  //                   ],
  //                 ),
  //               ),

  //               const SizedBox(height: 40),

  //               // Animation Section
  //               Center(
  //                 child: Container(
  //                   width: 200,
  //                   height: 200,
  //                   decoration: BoxDecoration(
  //                     color: Colors.white,
  //                     shape: BoxShape.circle,
  //                     boxShadow: [
  //                       BoxShadow(
  //                         color: textColor.withOpacity(0.1),
  //                         // blurRadius: 15,
  //                         offset: const Offset(0, 5),
  //                       ),
  //                     ],
  //                   ),
  //                   child: Lottie.asset(
  //                     'assets/animations/summarization.json',
  //                     fit: BoxFit.contain,
  //                   ),
  //                 ),
  //               ),

  //               const SizedBox(height: 30),
  //             ],  
  
  // Widget _buildKeyPoint(String text) {
  //   return Row(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Container(
  //         margin: const EdgeInsets.only(top: 6),
  //         width: 8,
  //         height: 8,
  //         decoration: BoxDecoration(
  //           color: bgColor,
  //           shape: BoxShape.circle,
  //         ),
  //       ),
  //       const SizedBox(width: 12),
  //       Expanded(
  //         child: Text(
  //           text,
  //           style: TextStyle(
  //             fontSize: 16,
  //             fontWeight: FontWeight.w400,
  //             color: textColor.withOpacity(0.8),
  //             height: 1.5,
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }