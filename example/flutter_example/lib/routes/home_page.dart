import 'package:equations_solver/routes/home_page/home_contents.dart';
import 'package:equations_solver/routes/home_page/recent_actions.dart';
import 'package:equations_solver/routes/utils/app_logo.dart';
import 'package:equations_solver/routes/utils/equation_scaffold.dart';
import 'package:flutter/material.dart';

/// This widget is the home page which shows a series of cards representing the
/// various solvers implemented in the app.
///
/// At the bottom there's a list with the latest 5 operations made by the user.
class HomePage extends StatelessWidget {
  const HomePage();

  @override
  Widget build(BuildContext context) {
    return EquationScaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // The logo at the top
            const AppLogo(),

            //700 bp
            LayoutBuilder(
              builder: (context, dimensions) {
                if (dimensions.maxWidth <= 700) {
                  return const _VerticalContents();
                }

                return const _HorizontalContents();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _VerticalContents extends StatelessWidget {
  const _VerticalContents();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        // The body of the home, which is a series of cards redirecting the
        // users to the various solvers
        HomeContents(),

        // Separator
        SizedBox(height: 60),

        // Shows the last 5 actions made with the app
        RecentActions(),
      ],
    );
  }
}

class _HorizontalContents extends StatelessWidget {
  const _HorizontalContents();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        // The body of the home, which is a series of cards redirecting the
        // users to the various solvers
        HomeContents(),

        // Separator
        SizedBox(width: 45),

        // Shows the last 5 actions made with the app
        RecentActions(),
      ],
    );
  }
}
