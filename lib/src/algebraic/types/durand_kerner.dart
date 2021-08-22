import 'dart:math' as math;

import 'package:equations/equations.dart';
import 'package:equations/src/algebraic/utils/sylvester_matrix.dart';
import 'package:equations/src/utils/math_utils.dart';

/// a
List<double> pr = List<double>.generate(1024, (_) => 0);

/// b
List<double> pi = List<double>.generate(1024, (_) => 0);

/// The Durand–Kerner method, also known as Weierstrass method, is a root
/// finding algorithm for solving polynomial equations. With this class, you
/// can find all the roots of a polynomial of any degree.
///
/// This is the preferred approach:
///
///  - when the polynomial degree is 5 or higher, use [DurandKerner];
///  - when the polynomial degree is 4, use [Quartic];
///  - when the polynomial degree is 3, use [Cubic];
///  - when the polynomial degree is 2, use [Quadratoc];
///  - when the polynomial degree is 1, use [Linear].
///
/// This algorithm requires an initial set of values to find the roots. This
/// implementation generates some random values if the user doesn't provide
/// some initial points to the algorithm.
///
/// Note that this algorithm does **NOT** always converge. To be more clear, it
/// is **NOT** true that for every polynomial, the set of initial vectors that
/// eventually converges to roots is open and dense.
class DurandKerner extends Algebraic with MathUtils {
  /// The initial guess from which the algorithm has to start finding the roots.
  ///
  /// By default, this is an empty list because this class can provide some
  /// pre-built values that are good in **most of** the cases (but not always).
  ///
  /// You can provide specific initial guesses with this param.
  ///
  /// The length of the [initialGuess] must match the length of the coefficients
  /// list.
  final List<Complex> initialGuess;

  /// The accuracy of the algorithm.
  final double precision;

  /// The maximum steps to be made by the algorithm.
  final int maxSteps;

  /// Instantiates a new object to find all the roots of a polynomial equation
  /// using the Durand-Kerner algorithm. The polynomial can have both complex
  /// ([Complex]) and real ([double]) values.
  ///
  ///   - [coefficients]: the coefficients of the polynomial;
  ///   - [initialGuess]: the initial guess from which the algorithm has to start
  ///   finding the roots;
  ///   - [precision]: the accuracy of the algorithm;
  ///   - [maxSteps]: the maximum steps to be made by the algorithm.
  ///
  /// Note that the coefficient with the highest degree goes first. For example,
  /// the coefficients of the `-5x^2 + 3x + i = 0` has to be inserted in the
  /// following way:
  ///
  /// ```dart
  /// final durandKerner = DurandKerner(
  ///   coefficients [
  ///     Complex.fromReal(-5),
  ///     Complex.fromReal(3),
  ///     Complex.i(),
  ///   ],
  /// );
  /// ```
  ///
  /// Since `-5` is the coefficient with the highest degree (2), it goes first.
  /// If the coefficients of your polynomial are only real numbers, consider
  /// using the [DurandKerner.realEquation()] constructor instead.
  DurandKerner({
    required List<Complex> coefficients,
    this.initialGuess = const [],
    this.precision = 1.0e-10,
    this.maxSteps = 2000,
  }) : super(coefficients);

  /// Instantiates a new object to find all the roots of a polynomial equation
  /// using the Durand-Kerner algorithm. The polynomial can have both complex
  /// ([Complex]) and real ([double]) values.
  ///
  ///   - [coefficients]: the coefficients of the polynomial;
  ///   - [initialGuess]: the initial guess from which the algorithm has to start
  ///   finding the roots;
  ///   - [precision]: the accuracy of the algorithm;
  ///   - [maxSteps]: the maximum steps to be made by the algorithm.
  ///
  /// Note that the coefficient with the highest degree goes first. For example,
  /// the coefficients of the `-5x^2 + 3x + 1 = 0` has to be inserted in the
  /// following way:
  ///
  /// ```dart
  /// final durandKerner = DurandKerner(
  ///   coefficients [-5, 3, 1],
  /// );
  /// ```
  ///
  /// Since `-5` is the coefficient with the highest degree (2), it goes first.
  /// If the coefficients of your polynomial contain complex numbers, consider
  /// using the [Laguerre()] constructor instead.
  DurandKerner.realEquation({
    required List<double> coefficients,
    this.initialGuess = const [],
    this.precision = 1.0e-10,
    this.maxSteps = 2000,
  }) : super.realEquation(coefficients);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is DurandKerner) {
      // The lengths of the data lists must match
      if (initialGuess.length != other.initialGuess.length) {
        return false;
      }

      // Each successful comparison increases a counter by 1. If all elements
      // are equal, then the counter will match the actual length of the data
      // list.
      var equalsCount = 0;

      for (var i = 0; i < initialGuess.length; ++i) {
        if (initialGuess[i] == other.initialGuess[i]) {
          ++equalsCount;
        }
      }

      // They must have the same runtime type AND all items must be equal.
      return super == other &&
          equalsCount == initialGuess.length &&
          precision == other.precision &&
          maxSteps == other.maxSteps;
    } else {
      return false;
    }
  }

  @override
  int get hashCode {
    var result = super.hashCode;

    result = 37 * result + initialGuess.hashCode;
    result = 37 * result + precision.hashCode;
    result = 37 * result + maxSteps.hashCode;

    return result;
  }

  @override
  int get degree => coefficients.length - 1;

  @override
  Algebraic derivative() {
    // Rather than always returning 'DurandKerner', if the degree is <= 4 there
    // is the possibility to return a more convenient object
    switch (coefficients.length) {
      case 1:
        return Constant(
          a: coefficients[0],
        ).derivative();
      case 2:
        return Linear(
          a: coefficients[0],
          b: coefficients[1],
        ).derivative();
      case 3:
        return Quadratic(
          a: coefficients[0],
          b: coefficients[1],
          c: coefficients[2],
        ).derivative();
      case 4:
        return Cubic(
          a: coefficients[0],
          b: coefficients[1],
          c: coefficients[2],
          d: coefficients[3],
        ).derivative();
      case 5:
        return Quartic(
          a: coefficients[0],
          b: coefficients[1],
          c: coefficients[2],
          d: coefficients[3],
          e: coefficients[4],
        ).derivative();
      case 6:
        final coeffs = _derivativeOf(coefficients);
        return Quartic(
          a: coeffs[0],
          b: coeffs[1],
          c: coeffs[2],
          d: coeffs[3],
          e: coeffs[4],
        );
      default:
        return DurandKerner(
          coefficients: _derivativeOf(coefficients),
          precision: precision,
          maxSteps: maxSteps,
        );
    }
  }

  @override
  Complex discriminant() {
    // Say that P(x) is the polynomial represented by this instance and
    // P'(x) is the derivative of P. In order to calculate the discriminant of
    // a polynomial, we need to first compute the resultant Res(A, A') which
    // is equivalent to the determinant of the Sylvester matrix.
    final sylvester = SylvesterMatrix(
      coefficients: coefficients,
    );

    // Computes Res(A, A') and then determines the sign according with the
    // degree of the polynomial.
    return sylvester.polynomialDiscriminant();
  }

  @override
  List<Complex> solutions() {
    // In case the polynomial was a constant, just return an empty array because
    // there are no solutions
    if (coefficients.length <= 1) {
      return [];
    }

    // Proceeding with the setup since the polynomial degree is >= 1.
    final coefficientsLength = coefficients.length;
    final reversedCoefficients = coefficients.reversed.toList();

    if (pr.length < coefficientsLength) {
      final newLength = _nextPow2(coefficientsLength);

      pr = List<double>.generate(newLength, (_) => 0);
      pi = List<double>.generate(newLength, (_) => 0);
    }

    // Filling the real values auxiliary array.
    for (var i = 0; i < coefficientsLength; ++i) {
      pr[i] = reversedCoefficients[i].real;
    }

    // Filling the imaginary values auxiliary array.
    for (var i = 0; i < coefficientsLength; ++i) {
      pi[i] = reversedCoefficients[i].imaginary;
    }

    // Scaling the various coefficients.
    var upperReal = pr[coefficientsLength - 1];
    var upperComplex = pi[coefficientsLength - 1];
    final squareSum = upperReal * upperReal + upperComplex * upperComplex;

    upperReal /= squareSum;
    upperComplex /= -squareSum;

    var k1 = 0.0;
    var k2 = 0.0;
    var k3 = 0.0;
    final s = upperComplex - upperReal;
    final t = upperReal + upperComplex;

    for (var i = 0; i < coefficientsLength - 1; ++i) {
      k1 = upperReal * (pr[i] + pi[i]);
      k2 = pr[i] * s;
      k3 = pi[i] * t;
      pr[i] = k1 - k3;
      pi[i] = k1 + k2;
    }

    pr[coefficientsLength - 1] = 1.0;
    pi[coefficientsLength - 1] = 0.0;

    // Using default values to compute the solutions. If they aren't provided,
    // we will generate default ones.
    if (initialGuess.isNotEmpty) {
      final real = initialGuess.map((e) => e.real).toList();
      final complex = initialGuess.map((e) => e.imaginary).toList();

      return _solve(
        realValues: real,
        imaginaryValues: complex,
      );
    } else {
      // If we're here, it means that no initial guesses were provided and so we
      // need to generate some good ones.
      final real = List<double>.generate(
        coefficientsLength - 1,
        (_) => 0.0,
      );
      final complex = List<double>.generate(
        coefficientsLength - 1,
        (_) => 0.0,
      );

      final factor = 0.65 * _bound(coefficientsLength);
      final multiplier = math.cos(0.25 * 2 * math.pi);

      for (var i = 0; i < coefficientsLength - 1; ++i) {
        real[i] = factor * multiplier;
        complex[i] = factor * math.sqrt(1.0 - multiplier * multiplier);
      }

      return _solve(
        realValues: real,
        imaginaryValues: complex,
      );
    }
  }

  /// Returns the coefficients of the derivative of a given polynomial.
  ///
  /// The [poly] parameter contains the coefficients of the polynomial whose
  /// derivative has to be computed.
  List<Complex> _derivativeOf(List<Complex> poly) {
    final newLength = coefficients.length - 1;

    // The derivative
    final result = List<Complex>.generate(
      newLength,
      (_) => const Complex.zero(),
    );

    // Evaluation of the derivative
    for (var i = 0; i < newLength; ++i) {
      result[i] = coefficients[i] * Complex.fromReal((newLength - i) * 1.0);
    }

    return result;
  }

  /// Creates a **deep** copy of this object with the given fields replaced
  /// with the new values.
  DurandKerner copyWith({
    List<Complex>? coefficients,
    List<Complex>? initialGuess,
    double? precision,
    int? maxSteps,
  }) =>
      DurandKerner(
        coefficients: coefficients ?? List<Complex>.from(this.coefficients),
        initialGuess: initialGuess ?? List<Complex>.from(this.initialGuess),
        precision: precision ?? this.precision,
        maxSteps: maxSteps ?? this.maxSteps,
      );

  /// Determines whether subsequent points are close enough (where "enough" is
  /// defined by [precision].
  bool _near(double a, double b, double c, double d) {
    final qa = a - c;
    final qb = b - d;

    return (qa * qa + qb * qb) < precision;
  }

  /// Returns the maximum magnitude of the complex number, increased by 1.
  double _bound(int value) {
    var bound = 0.0;

    for (var i = 0; i < value; ++i) {
      bound = math.max(bound, pr[i] * pr[i] + pi[i] * pi[i]);
    }

    return 1.0 + math.sqrt(bound);
  }

  /// Rounds a number to the closest power of 2. Some examples are:
  ///
  ///  - 0 rounds to 1
  ///  - 1 rounds to 1
  ///  - 2 rounds to 2
  ///  - 3 rounds to 4
  ///  - 4 rounds to 4
  ///  - 5 rounds to 8
  ///  - 6 rounds to 8
  ///  - 7 rounds to 8
  ///  - 8 rounds to 8
  ///  - 9 rounds to 16
  ///  - 10 rounds to 16
  int _nextPow2(int value) => log2(value.abs()).ceil();

  /// The Durand-Kerner algorithm that finds the roots of the polynomial.
  List<Complex> _solve({
    required List<double> realValues,
    required List<double> imaginaryValues,
  }) {
    final n = coefficients.length;
    final m = realValues.length;

    var pa = 0.0;
    var pb = 0.0;
    var qa = 0.0;
    var qb = 0.0;
    var k1 = 0.0;
    var k2 = 0.0;
    var k3 = 0.0;
    var na = 0.0;
    var nb = 0.0;
    var s1 = 0.0;
    var s2 = 0.0;

    for (var i = 0; i < maxSteps; ++i) {
      var d = 0.0;
      for (var j = 0; j < m; ++j) {
        //Read in zj
        pa = realValues[j];
        pb = imaginaryValues[j];

        //Compute denominator
        //
        //  (zj - z0) * (zj - z1) * ... * (zj - z_{n-1})
        //
        var a = 1.0;
        var b = 1.0;
        for (var k = 0; k < m; ++k) {
          if (k == j) {
            continue;
          }
          qa = pa - realValues[k];
          qb = pb - imaginaryValues[k];
          if (qa * qa + qb * qb < precision) {
            continue;
          }
          k1 = qa * (a + b);
          k2 = a * (qb - qa);
          k3 = b * (qa + qb);
          a = k1 - k3;
          b = k1 + k2;
        }

        //Compute numerator
        na = pr[n - 1];
        nb = pi[n - 1];
        s1 = pb - pa;
        s2 = pa + pb;
        for (var k = n - 2; k >= 0; --k) {
          k1 = pa * (na + nb);
          k2 = na * s1;
          k3 = nb * s2;
          na = k1 - k3 + pr[k];
          nb = k1 + k2 + pi[k];
        }

        //Compute reciprocal
        k1 = a * a + b * b;
        if (k1.abs() > 1.0e-10) {
          a /= k1;
          b /= -k1;
        } else {
          a = 1.0;
          b = 0.0;
        }

        //Multiply and accumulate
        k1 = na * (a + b);
        k2 = a * (nb - na);
        k3 = b * (na + nb);

        qa = k1 - k3;
        qb = k1 + k2;

        realValues[j] = pa - qa;
        imaginaryValues[j] = pb - qb;

        d = math.max(d, math.max(qa.abs(), qb.abs()));
      }

      //If converged, exit early
      if (d < precision) {
        break;
      }
    }

    //Post process: Combine any repeated roots
    var count = 0.0;

    for (var i = 0; i < m; ++i) {
      count = 1;
      var a = realValues[i];
      var b = imaginaryValues[i];
      for (var j = 0; j < m; ++j) {
        if (i == j) {
          continue;
        }
        if (_near(
          realValues[i],
          imaginaryValues[i],
          realValues[j],
          imaginaryValues[j],
        )) {
          ++count;
          a += realValues[j];
          b += imaginaryValues[j];
        }
      }
      if (count > 1) {
        a /= count;
        b /= count;
        for (var j = 0; j < m; ++j) {
          if (i == j) {
            continue;
          }
          if (_near(
            realValues[i],
            imaginaryValues[i],
            realValues[j],
            imaginaryValues[j],
          )) {
            realValues[j] = a;
            imaginaryValues[j] = b;
          }
        }
        realValues[i] = a;
        imaginaryValues[i] = b;
      }
    }

    final roots = List<Complex>.generate(
      n - 1,
      (_) => const Complex.zero(),
    );

    for (var i = 0; i < n - 1; ++i) {
      roots[i] = Complex(realValues[i], imaginaryValues[i]);
    }

    return roots;
  }
}
