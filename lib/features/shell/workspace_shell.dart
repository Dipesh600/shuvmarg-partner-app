import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import 'workspace_nav.dart';

/// The workspace chrome: cream canvas plus the floating brand-coloured bottom
/// navigation bar.
///
/// Web reference (`WorkspaceLayout.tsx`):
/// ```jsx
/// <div className="bg-[#FAF7F2] ...">
///   <WorkspaceNav />
///   <SmoothScrollArea className="pb-16 pt-16 ...">
///     <main className="max-w-[1280px] mx-auto w-full px-4 py-4">
///       {children}
///     </main>
///   </SmoothScrollArea>
/// </div>
/// ```
///
/// Because the nav **floats** above the content rather than displacing it, any
/// scrollable placed in [child] must reserve [AppSpacing.navReservedSpace] at
/// the bottom or its last item will sit under the bar. [WorkspacePage] does
/// this for you.
class WorkspaceShell extends StatelessWidget {
  const WorkspaceShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      // The nav floats over content, so it can't be `bottomNavigationBar`
      // (which reserves layout space and would break the float).
      body: Stack(
        children: [
          Positioned.fill(child: child),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: WorkspaceNavBar(
                currentIndex: currentIndex,
                onDestinationSelected: onDestinationSelected,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A scrollable page body sized for the workspace shell.
///
/// Applies the web's gutters (`px-4 py-4`) and reserves room for the floating
/// nav so the final card is never obscured.
class WorkspacePage extends StatelessWidget {
  const WorkspacePage({
    super.key,
    required this.children,
    this.padding,
    this.scrollController,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      padding:
          padding ??
          const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.md,
            AppSpacing.gutter,
            AppSpacing.navReservedSpace,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
