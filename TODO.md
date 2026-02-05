# Future Improvements & Technical Debt

## Critical
- [ ] **Deep Dive: Camera Stability on Legacy/Specific Devices (Xiaomi MI 9)**
    - **Issue**: The app loses connection/crashes when launching the camera on some devices, likely due to aggressive OS memory management or native driver conflicts.
    - **Current Hotfixes (Applied)**:
        - Disabled Impeller (Vulkan).
        - Enabled `android:largeHeap="true"`.
        - Implemented [retrieveLostData](file:///c:/development/shape_log/lib/features/body_tracker/presentation/pages/body_measurement_entry_page.dart#87-104) loop for Activity recreation.
    - **Recommended Future Actions**:
        - **Memory Profiling**: using Android Studio Profiler to check for spikes during `image_picker` launch.
        - **Compression**: Implement aggressive image compression *before* loading into memory (using `flutter_image_compress`).
        - **Alternative Libs**: Evaluate migrating to `camerax` custom implementation instead of generic intent-based `image_picker` if stability continues to be a problem.
