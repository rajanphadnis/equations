// coverage:ignore-file
import 'dart:math' as math;

import 'package:equations/equations.dart';
import 'package:equations/src/system/utils/matrix/decompositions/eigenvalue_decomposition/eigen_decomposition.dart';
import 'package:equations/src/utils/math_utils.dart';

/// {@macro eigendecomposition_class_header}
///
/// This class performs the eigendecomposition on [RealMatrix] types.
class EigendecompositionReal extends EigenDecomposition<double, RealMatrix>
    with MathUtils {
  /// Requires the [matrix] matrix to be decomposed.
  const EigendecompositionReal({
    required super.matrix,
  });

  @override
  List<RealMatrix> decompose() {
    // Variables setup
    final realEigenvalues = List<double>.generate(
      matrix.rowCount,
      (_) => 0.0,
    );
    final complexEigenvalues = List<double>.generate(
      matrix.rowCount,
      (_) => 0.0,
    );
    final hessenbergValues = List<double>.generate(
      matrix.columnCount,
      (_) => 0.0,
    );
    final eigenVectors = matrix.toListOfList();

    // Starting the Eigendecomposition algorithm.
    if (matrix.isSymmetric()) {
      // Tridiagonalize.
      _tridiagonalForm(
        eigenVectors: eigenVectors,
        complexEigenvalues: complexEigenvalues,
        realEigenvalues: realEigenvalues,
      );

      // Diagonalize.
      _qlTridiagonal(
        eigenVectors: eigenVectors,
        complexEigenvalues: complexEigenvalues,
        realEigenvalues: realEigenvalues,
      );
    } else {
      final hessenbergCache = matrix.toListOfList();

      // Reducing to Hessenberg form.
      _nonsymmetricHessReduction(
        eigenVectors: eigenVectors,
        hessenbergCache: hessenbergCache,
        hessenbergValues: hessenbergValues,
      );

      // Converting into real Schur form.
      _hessenbergToSchur(
        hessenbergCache: hessenbergCache,
        eigenVectors: eigenVectors,
        realEigenvalues: realEigenvalues,
        complexEigenvalues: complexEigenvalues,
      );
    }

    // Now there's just the need to build 'Q' and 'V'.
    final dataMatrixD = List<List<double>>.generate(
      matrix.rowCount,
      (_) => List<double>.generate(
        matrix.columnCount,
        (_) => 0,
      ),
    );

    for (var i = 0; i < matrix.rowCount; ++i) {
      dataMatrixD[i][i] = realEigenvalues[i];

      if (complexEigenvalues[i] > 0) {
        dataMatrixD[i][i + 1] = complexEigenvalues[i];
      } else if (complexEigenvalues[i] < 0) {
        dataMatrixD[i][i - 1] = complexEigenvalues[i];
      }
    }

    // Building D and V.
    final D = RealMatrix.fromData(
      rows: matrix.rowCount,
      columns: matrix.columnCount,
      data: dataMatrixD,
    );

    final V = RealMatrix.fromData(
      rows: eigenVectors.length,
      columns: eigenVectors.first.length,
      data: eigenVectors,
    );

    // Returning the results.
    return [
      V,
      D,
      V.inverse(),
    ];
  }

  /// Using Householder reduction to obtain the tridiagonal form.
  void _tridiagonalForm({
    required List<double> realEigenvalues,
    required List<double> complexEigenvalues,
    required List<List<double>> eigenVectors,
  }) {
    for (var j = 0; j < matrix.rowCount; j++) {
      realEigenvalues[j] = eigenVectors.get(matrix.rowCount - 1, j);
    }

    // Householder reduction to tridiagonal form.
    for (var i = matrix.rowCount - 1; i > 0; i--) {
      var scale = 0.0;
      var h = 0.0;
      for (var k = 0; k < i; k++) {
        scale = scale + realEigenvalues[k].abs();
      }
      if (scale == 0.0) {
        complexEigenvalues[i] = realEigenvalues[i - 1];
        for (var j = 0; j < i; j++) {
          realEigenvalues[j] = eigenVectors.get(i - 1, j);
          eigenVectors
            ..set(i, j, 0)
            ..set(j, i, 0);
        }
      } else {
        // Generating the Householder vector.
        for (var k = 0; k < i; k++) {
          realEigenvalues[k] /= scale;
          h += realEigenvalues[k] * realEigenvalues[k];
        }
        var f = realEigenvalues[i - 1];
        var g = math.sqrt(h);
        if (f > 0) {
          g = -g;
        }
        complexEigenvalues[i] = scale * g;
        h = h - f * g;
        realEigenvalues[i - 1] = f - g;
        for (var j = 0; j < i; j++) {
          complexEigenvalues[j] = 0.0;
        }

        for (var j = 0; j < i; j++) {
          f = realEigenvalues[j];
          eigenVectors.set(j, i, f);
          g = complexEigenvalues[j] + eigenVectors.get(j, j) * f;
          for (var k = j + 1; k <= i - 1; k++) {
            g += eigenVectors.get(k, j) * realEigenvalues[k];
            complexEigenvalues[k] += eigenVectors.get(k, j) * f;
          }
          complexEigenvalues[j] = g;
        }
        f = 0.0;
        for (var j = 0; j < i; j++) {
          complexEigenvalues[j] /= h;
          f += complexEigenvalues[j] * realEigenvalues[j];
        }
        final hh = f / (h + h);
        for (var j = 0; j < i; j++) {
          complexEigenvalues[j] -= hh * realEigenvalues[j];
        }
        for (var j = 0; j < i; j++) {
          f = realEigenvalues[j];
          g = complexEigenvalues[j];
          for (var k = j; k <= i - 1; k++) {
            final val = f * complexEigenvalues[k] + g * realEigenvalues[k];
            eigenVectors.set(
              k,
              j,
              eigenVectors.get(k, j) - val,
            );
          }
          realEigenvalues[j] = eigenVectors.get(i - 1, j);
          eigenVectors.set(i, j, 0);
        }
      }
      realEigenvalues[i] = h;
    }

    for (var i = 0; i < matrix.rowCount - 1; i++) {
      eigenVectors
        ..set(matrix.rowCount - 1, i, eigenVectors.get(i, i))
        ..set(i, i, 1);
      final h = realEigenvalues[i + 1];
      if (h != 0.0) {
        for (var k = 0; k <= i; k++) {
          realEigenvalues[k] = eigenVectors.get(k, i + 1) / h;
        }
        for (var j = 0; j <= i; j++) {
          var g = 0.0;
          for (var k = 0; k <= i; k++) {
            g += eigenVectors.get(k, i + 1) * eigenVectors.get(k, j);
          }
          for (var k = 0; k <= i; k++) {
            eigenVectors.set(
              k,
              j,
              eigenVectors.get(k, j) - g * realEigenvalues[k],
            );
          }
        }
      }
      for (var k = 0; k <= i; k++) {
        eigenVectors.set(k, i + 1, 0);
      }
    }
    for (var j = 0; j < matrix.rowCount; j++) {
      realEigenvalues[j] = eigenVectors.get(matrix.rowCount - 1, j);
      eigenVectors.set(matrix.rowCount - 1, j, 0);
    }
    eigenVectors.set(matrix.rowCount - 1, matrix.rowCount - 1, 1);
    complexEigenvalues.first = 0.0;
  }

  /// Applying the tridiagonal QL algorithm, which is an efficient method to
  /// find eigenvalues of a matrix.
  void _qlTridiagonal({
    required List<double> realEigenvalues,
    required List<double> complexEigenvalues,
    required List<List<double>> eigenVectors,
  }) {
    for (var i = 1; i < matrix.rowCount; i++) {
      complexEigenvalues[i - 1] = complexEigenvalues[i];
    }
    complexEigenvalues[matrix.rowCount - 1] = 0.0;

    var f = 0.0;
    var tst1 = 0.0;
    final eps = math.pow(2.0, -52.0);
    for (var l = 0; l < matrix.rowCount; l++) {
      tst1 = math.max(
        tst1,
        realEigenvalues[l].abs() + complexEigenvalues[l].abs(),
      );
      var m = l;
      while (m < matrix.rowCount) {
        if (complexEigenvalues[m].abs() <= eps * tst1) {
          break;
        }
        m++;
      }

      // If 'm == l', then d[l] is an eigenvalue and thus store it.
      // If 'm != l', proceed with the iteration.
      if (m > l) {
        do {
          // Computing the implicit shift.
          var g = realEigenvalues[l];
          var p = (realEigenvalues[l + 1] - g) / (2.0 * complexEigenvalues[l]);
          var r = hypot(p, 1);
          if (p < 0) {
            r = -r;
          }
          realEigenvalues[l] = complexEigenvalues[l] / (p + r);
          realEigenvalues[l + 1] = complexEigenvalues[l] * (p + r);
          final dl1 = realEigenvalues[l + 1];
          var h = g - realEigenvalues[l];
          for (var i = l + 2; i < matrix.rowCount; i++) {
            realEigenvalues[i] -= h;
          }
          f = f + h;

          // Implicit QL transformation.
          p = realEigenvalues[m];
          var c = 1.0;
          var c2 = c;
          var c3 = c;
          final el1 = complexEigenvalues[l + 1];
          var s = 0.0;
          var s2 = 0.0;
          for (var i = m - 1; i >= l; i--) {
            c3 = c2;
            c2 = c;
            s2 = s;
            g = c * complexEigenvalues[i];
            h = c * p;
            r = hypot(p, complexEigenvalues[i]);
            complexEigenvalues[i + 1] = s * r;
            s = complexEigenvalues[i] / r;
            c = p / r;
            p = c * realEigenvalues[i] - s * g;
            realEigenvalues[i + 1] = h + s * (c * g + s * realEigenvalues[i]);

            for (var k = 0; k < matrix.rowCount; k++) {
              h = eigenVectors.get(k, i + 1);
              eigenVectors
                ..set(k, i + 1, s * eigenVectors.get(k, i) + c * h)
                ..set(k, i, c * eigenVectors.get(k, i) - s * h);
            }
          }
          p = -s * s2 * c3 * el1 * complexEigenvalues[l] / dl1;
          complexEigenvalues[l] = s * p;
          realEigenvalues[l] = c * p;
        } while (complexEigenvalues[l].abs() > eps * tst1);
      }
      realEigenvalues[l] = realEigenvalues[l] + f;
      complexEigenvalues[l] = 0.0;
    }

    // Sorting eigenvalues and their corresponding vectors.
    for (var i = 0; i < matrix.rowCount - 1; i++) {
      var k = i;
      var p = realEigenvalues[i];
      for (var j = i + 1; j < matrix.rowCount; j++) {
        if (realEigenvalues[j] < p) {
          k = j;
          p = realEigenvalues[j];
        }
      }
      if (k != i) {
        realEigenvalues[k] = realEigenvalues[i];
        realEigenvalues[i] = p;
        for (var j = 0; j < matrix.rowCount; j++) {
          p = eigenVectors.get(j, i);
          eigenVectors
            ..set(j, i, eigenVectors.get(j, k))
            ..set(j, k, p);
        }
      }
    }
  }

  /// Nonsymmetric reduction to the Hessenberg form.
  void _nonsymmetricHessReduction({
    required List<List<double>> hessenbergCache,
    required List<double> hessenbergValues,
    required List<List<double>> eigenVectors,
  }) {
    final high = matrix.rowCount - 1;

    for (var m = 1; m <= high - 1; m++) {
      var scale = 0.0;
      for (var i = m; i <= high; i++) {
        scale = scale + hessenbergCache.get(i, m - 1).abs();
      }
      if (scale != 0.0) {
        // Householder transformation here.
        var h = 0.0;
        for (var i = high; i >= m; i--) {
          hessenbergValues[i] = hessenbergCache.get(i, m - 1) / scale;
          h += hessenbergValues[i] * hessenbergValues[i];
        }
        var g = math.sqrt(h);
        if (hessenbergValues[m] > 0) {
          g = -g;
        }
        h -= hessenbergValues[m] * g;
        hessenbergValues[m] = hessenbergValues[m] - g;

        // Doing the Householder similarity transformation.
        //
        // H = (I-u*u'/h) x H x (I-u*u')/h)
        for (var j = m; j < matrix.rowCount; j++) {
          var f = 0.0;
          for (var i = high; i >= m; i--) {
            f += hessenbergValues[i] * hessenbergCache.get(i, j);
          }
          f = f / h;
          for (var i = m; i <= high; i++) {
            hessenbergCache.set(
              i,
              j,
              hessenbergCache.get(i, j) - f * hessenbergValues[i],
            );
          }
        }

        for (var i = 0; i <= high; i++) {
          var f = 0.0;
          for (var j = high; j >= m; j--) {
            f += hessenbergValues[j] * hessenbergCache.get(i, j);
          }
          f = f / h;
          for (var j = m; j <= high; j++) {
            final val = hessenbergCache.get(i, j) - f * hessenbergValues[j];
            hessenbergCache.set(i, j, val);
          }
        }
        hessenbergValues[m] = scale * hessenbergValues[m];
        hessenbergCache.set(m, m - 1, scale * g);
      }
    }

    for (var i = 0; i < matrix.rowCount; i++) {
      for (var j = 0; j < matrix.rowCount; j++) {
        eigenVectors.set(i, j, i == j ? 1.0 : 0.0);
      }
    }

    for (var m = high - 1; m >= 1; m--) {
      if (hessenbergCache.get(m, m - 1) != 0.0) {
        for (var i = m + 1; i <= high; i++) {
          hessenbergValues[i] = hessenbergCache.get(i, m - 1);
        }
        for (var j = m; j <= high; j++) {
          var g = 0.0;
          for (var i = m; i <= high; i++) {
            g += hessenbergValues[i] * eigenVectors.get(i, j);
          }

          // Double division avoids underflow issues.
          g = (g / hessenbergValues[m]) / hessenbergCache.get(m, m - 1);
          for (var i = m; i <= high; i++) {
            final vectorVal = eigenVectors.get(i, j) + g * hessenbergValues[i];
            eigenVectors.set(i, j, vectorVal);
          }
        }
      }
    }
  }

  Complex _complexDiv(double xr, double xi, double yr, double yi) {
    if (yr.abs() > yi.abs()) {
      final r = yi / yr;
      final d = yr + r * yi;

      return Complex((xr + r * xi) / d, (xi - r * xr) / d);
    } else {
      final r = yr / yi;
      final d = yi + r * yr;

      return Complex((r * xr + xi) / d, (r * xi - xr) / d);
    }
  }

  /// Nonsymmetric reduction from the Hessenbergform to the real Schur form.
  void _hessenbergToSchur({
    required List<double> realEigenvalues,
    required List<double> complexEigenvalues,
    required List<List<double>> hessenbergCache,
    required List<List<double>> eigenVectors,
  }) {
    final nn = matrix.rowCount;
    var n = nn - 1;
    const low = 0;
    final high = nn - 1;
    final eps = math.pow(2.0, -52.0);
    var exshift = 0.0;
    var p = 0.0;
    var q = 0.0;
    var r = 0.0;
    var s = 0.0;
    var z = 0.0;
    var t = 0.0;
    var w = 0.0;
    var x = 0.0;
    var y = 0.0;

    var norm = 0.0;
    for (var i = 0; i < nn; i++) {
      if (i < low || i > high) {
        realEigenvalues[i] = hessenbergCache.get(i, i);
        complexEigenvalues[i] = 0.0;
      }
      for (var j = math.max(i - 1, 0); j < nn; j++) {
        norm = norm + hessenbergCache.get(i, j).abs();
      }
    }

    var iter = 0;
    while (n >= low) {
      // Looking for single small sub-diagonal elements.
      var l = n;
      while (l > low) {
        s = hessenbergCache.get(l - 1, l - 1).abs() +
            hessenbergCache.get(l, l).abs();
        if (s == 0.0) {
          s = norm;
        }
        if (hessenbergCache.get(l, l - 1).abs() < eps * s) {
          break;
        }
        l--;
      }

      // CASE 1: One root found
      if (l == n) {
        hessenbergCache.set(n, n, hessenbergCache.get(n, n) + exshift);
        realEigenvalues[n] = hessenbergCache.get(n, n);
        complexEigenvalues[n] = 0.0;
        n--;
        iter = 0;
      } else if (l == n - 1) {
        // CASE 2: 2 roots found.
        w = hessenbergCache.get(n, n - 1) * hessenbergCache.get(n - 1, n);
        p = (hessenbergCache.get(n - 1, n - 1) - hessenbergCache.get(n, n)) /
            2.0;
        q = p * p + w;
        z = math.sqrt(q.abs());
        hessenbergCache
          ..set(n, n, hessenbergCache.get(n, n) + exshift)
          ..set(
            n - 1,
            n - 1,
            hessenbergCache.get(n - 1, n - 1) + exshift,
          );
        x = hessenbergCache.get(n, n);

        // Real roots.
        if (q >= 0) {
          if (p >= 0) {
            z = p + z;
          } else {
            z = p - z;
          }
          realEigenvalues[n - 1] = x + z;
          realEigenvalues[n] = realEigenvalues[n - 1];
          if (z != 0.0) {
            realEigenvalues[n] = x - w / z;
          }
          complexEigenvalues[n - 1] = 0.0;
          complexEigenvalues[n] = 0.0;
          x = hessenbergCache.get(n, n - 1);
          s = x.abs() + z.abs();
          p = x / s;
          q = z / s;
          r = math.sqrt(p * p + q * q);
          p = p / r;
          q = q / r;

          // Row modifications
          for (var j = n - 1; j < nn; j++) {
            z = hessenbergCache.get(n - 1, j);
            hessenbergCache
              ..set(
                n - 1,
                j,
                q * z + p * hessenbergCache.get(n, j),
              )
              ..set(n, j, q * hessenbergCache.get(n, j) - p * z);
          }

          // Column modifications
          for (var i = 0; i <= n; i++) {
            z = hessenbergCache.get(i, n - 1);
            hessenbergCache
              ..set(
                i,
                n - 1,
                q * z + p * hessenbergCache.get(i, n),
              )
              ..set(i, n, q * hessenbergCache.get(i, n) - p * z);
          }

          for (var i = low; i <= high; i++) {
            z = eigenVectors.get(i, n - 1);
            eigenVectors
              ..set(i, n - 1, q * z + p * eigenVectors.get(i, n))
              ..set(i, n, q * eigenVectors.get(i, n) - p * z);
          }

          // Complex roots.
        } else {
          realEigenvalues[n - 1] = x + p;
          realEigenvalues[n] = x + p;
          complexEigenvalues[n - 1] = z;
          complexEigenvalues[n] = -z;
        }
        n = n - 2;
        iter = 0;
      } else {
        // Form shift
        x = hessenbergCache.get(n, n);
        y = 0.0;
        w = 0.0;
        if (l < n) {
          y = hessenbergCache.get(n - 1, n - 1);
          w = hessenbergCache.get(n, n - 1) * hessenbergCache.get(n - 1, n);
        }

        if (iter == 10) {
          exshift += x;
          for (var i = low; i <= n; i++) {
            hessenbergCache.set(i, i, hessenbergCache.get(i, i) - x);
          }
          s = hessenbergCache.get(n, n - 1).abs() +
              hessenbergCache.get(n - 1, n - 2).abs();
          x = y = s * 0.75;
          w = -0.4375 * s * s;
        }

        if (iter == 30) {
          s = (y - x) / 2.0;
          s = s * s + w;
          if (s > 0) {
            s = math.sqrt(s);
            if (y < x) {
              s = -s;
            }
            s = x - w / ((y - x) / 2.0 + s);
            for (var i = low; i <= n; i++) {
              hessenbergCache.set(i, i, hessenbergCache.get(i, i) - s);
            }
            exshift += s;
            x = y = w = 0.964;
          }
        }

        iter = iter + 1;

        var m = n - 2;
        while (m >= l) {
          z = hessenbergCache.get(m, m);
          r = x - z;
          s = y - z;
          p = (r * s - w) / hessenbergCache.get(m + 1, m) +
              hessenbergCache.get(m, m + 1);
          q = hessenbergCache.get(m + 1, m + 1) - z - r - s;
          r = hessenbergCache.get(m + 2, m + 1);
          s = p.abs() + q.abs() + r.abs();
          p = p / s;
          q = q / s;
          r = r / s;
          if (m == l) {
            break;
          }

          if (hessenbergCache.get(m, m - 1).abs() * (q.abs() + r.abs()) <
              eps *
                  (p.abs() *
                      (hessenbergCache.get(m - 1, m - 1).abs() +
                          z.abs() +
                          hessenbergCache.get(m + 1, m + 1).abs()))) {
            break;
          }
          m--;
        }

        for (var i = m + 2; i <= n; i++) {
          hessenbergCache.set(i, i - 2, 0);
          if (i > m + 2) {
            hessenbergCache.set(i, i - 3, 0);
          }
        }

        // Double QR step involving rows l:n and columns m:n.
        for (var k = m; k <= n - 1; k++) {
          final notlast = k != n - 1;
          if (k != m) {
            p = hessenbergCache.get(k, k - 1);
            q = hessenbergCache.get(k + 1, k - 1);
            r = notlast ? hessenbergCache.get(k + 2, k - 1) : 0.0;
            x = p.abs() + q.abs() + r.abs();
            if (x == 0.0) {
              continue;
            }
            p = p / x;
            q = q / x;
            r = r / x;
          }

          s = math.sqrt(p * p + q * q + r * r);
          if (p < 0) {
            s = -s;
          }
          if (s != 0) {
            if (k != m) {
              hessenbergCache.set(k, k - 1, -s * x);
            } else if (l != m) {
              hessenbergCache.set(k, k - 1, -hessenbergCache.get(k, k - 1));
            }
            p = p + s;
            x = p / s;
            y = q / s;
            z = r / s;
            q = q / p;
            r = r / p;

            for (var j = k; j < nn; j++) {
              p = hessenbergCache.get(k, j) + q * hessenbergCache.get(k + 1, j);
              if (notlast) {
                p = p + r * hessenbergCache.get(k + 2, j);
                hessenbergCache.set(
                  k + 2,
                  j,
                  hessenbergCache.get(k + 2, j) - p * z,
                );
              }
              hessenbergCache
                ..set(k, j, hessenbergCache.get(k, j) - p * x)
                ..set(
                  k + 1,
                  j,
                  hessenbergCache.get(k + 1, j) - p * y,
                );
            }

            for (var i = 0; i <= math.min(n, k + 3); i++) {
              p = x * hessenbergCache.get(i, k) +
                  y * hessenbergCache.get(i, k + 1);
              if (notlast) {
                p = p + z * hessenbergCache.get(i, k + 2);
                hessenbergCache.set(
                  i,
                  k + 2,
                  hessenbergCache.get(i, k + 2) - p * r,
                );
              }
              hessenbergCache
                ..set(i, k, hessenbergCache.get(i, k) - p)
                ..set(
                  i,
                  k + 1,
                  hessenbergCache.get(i, k + 1) - p * q,
                );
            }

            for (var i = low; i <= high; i++) {
              p = x * eigenVectors.get(i, k) + y * eigenVectors.get(i, k + 1);
              if (notlast) {
                p = p + z * eigenVectors.get(i, k + 2);
                eigenVectors.set(i, k + 2, eigenVectors.get(i, k + 2) - p * r);
              }
              eigenVectors
                ..set(i, k, eigenVectors.get(i, k) - p)
                ..set(i, k + 1, eigenVectors.get(i, k + 1) - p * q);
            }
          }
        }
      }
    }

    if (norm == 0.0) {
      return;
    }

    for (n = nn - 1; n >= 0; n--) {
      p = realEigenvalues[n];
      q = complexEigenvalues[n];

      if (q == 0) {
        var l = n;
        hessenbergCache.set(n, n, 1);
        for (var i = n - 1; i >= 0; i--) {
          w = hessenbergCache.get(i, i) - p;
          r = 0.0;
          for (var j = l; j <= n; j++) {
            r = r + hessenbergCache.get(i, j) * hessenbergCache.get(j, n);
          }
          if (complexEigenvalues[i] < 0.0) {
            z = w;
            s = r;
          } else {
            l = i;
            if (complexEigenvalues[i] == 0.0) {
              if (w != 0.0) {
                hessenbergCache.set(i, n, -r / w);
              } else {
                hessenbergCache.set(i, n, -r / (eps * norm));
              }

              // Solve real equations

            } else {
              x = hessenbergCache.get(i, i + 1);
              y = hessenbergCache.get(i + 1, i);
              q = (realEigenvalues[i] - p) * (realEigenvalues[i] - p) +
                  complexEigenvalues[i] * complexEigenvalues[i];
              t = (x * s - z * r) / q;
              hessenbergCache.set(i, n, t);
              if (x.abs() > z.abs()) {
                hessenbergCache.set(i + 1, n, (-r - w * t) / x);
              } else {
                hessenbergCache.set(i + 1, n, (-s - y * t) / z);
              }
            }

            t = hessenbergCache.get(i, n).abs();
            if ((eps * t) * t > 1) {
              for (var j = i; j <= n; j++) {
                hessenbergCache.set(j, n, hessenbergCache.get(j, n) / t);
              }
            }
          }
        }
      } else if (q < 0) {
        var l = n - 1;
        if (hessenbergCache.get(n, n - 1).abs() >
            hessenbergCache.get(n - 1, n).abs()) {
          hessenbergCache
            ..set(n - 1, n - 1, q / hessenbergCache.get(n, n - 1))
            ..set(
              n - 1,
              n,
              -(hessenbergCache.get(n, n) - p) / hessenbergCache.get(n, n - 1),
            );
        } else {
          final division = _complexDiv(
            0,
            -hessenbergCache.get(n - 1, n),
            hessenbergCache.get(n - 1, n - 1) - p,
            q,
          );
          hessenbergCache
            ..set(n - 1, n - 1, division.real)
            ..set(n - 1, n, division.imaginary);
        }
        hessenbergCache
          ..set(n, n - 1, 0)
          ..set(n, n, 1);
        for (var i = n - 2; i >= 0; i--) {
          var ra = 0.0;
          var sa = 0.0;
          var vr = 0.0;
          var vi = 0.0;
          ra = 0.0;
          sa = 0.0;
          for (var j = l; j <= n; j++) {
            ra = ra + hessenbergCache.get(i, j) * hessenbergCache.get(j, n - 1);
            sa = sa + hessenbergCache.get(i, j) * hessenbergCache.get(j, n);
          }
          w = hessenbergCache.get(i, i) - p;

          if (complexEigenvalues[i] < 0.0) {
            z = w;
            r = ra;
            s = sa;
          } else {
            l = i;
            if (complexEigenvalues[i] == 0) {
              final division = _complexDiv(-ra, -sa, w, q);
              hessenbergCache
                ..set(i, n - 1, division.real)
                ..set(i, n, division.imaginary);
            } else {
              x = hessenbergCache.get(i, i + 1);
              y = hessenbergCache.get(i + 1, i);
              vr = (realEigenvalues[i] - p) * (realEigenvalues[i] - p) +
                  complexEigenvalues[i] * complexEigenvalues[i] -
                  q * q;
              vi = (realEigenvalues[i] - p) * 2.0 * q;
              if (vr == 0.0 && vi == 0.0) {
                vr = eps *
                    norm *
                    (w.abs() + q.abs() + x.abs() + y.abs() + z.abs());
              }
              final division = _complexDiv(
                x * r - z * ra + q * sa,
                x * s - z * sa - q * ra,
                vr,
                vi,
              );
              hessenbergCache
                ..set(i, n - 1, division.real)
                ..set(i, n, division.imaginary);
              if (x.abs() > (z.abs() + q.abs())) {
                final mult = q * hessenbergCache.get(i, n);
                final pmult = q * hessenbergCache.get(i, n - 1);

                hessenbergCache
                  ..set(
                    i + 1,
                    n - 1,
                    (-ra - w * hessenbergCache.get(i, n - 1) + mult) / x,
                  )
                  ..set(
                    i + 1,
                    n,
                    (-sa - w * hessenbergCache.get(i, n) - pmult) / x,
                  );
              } else {
                final division = _complexDiv(
                  -r - y * hessenbergCache.get(i, n - 1),
                  -s - y * hessenbergCache.get(i, n),
                  z,
                  q,
                );
                hessenbergCache
                  ..set(i + 1, n - 1, division.real)
                  ..set(i + 1, n, division.imaginary);
              }
            }

            t = math.max(
              hessenbergCache.get(i, n - 1).abs(),
              hessenbergCache.get(i, n).abs(),
            );
            if ((eps * t) * t > 1) {
              for (var j = i; j <= n; j++) {
                hessenbergCache
                  ..set(
                    j,
                    n - 1,
                    hessenbergCache.get(j, n - 1) / t,
                  )
                  ..set(j, n, hessenbergCache.get(j, n) / t);
              }
            }
          }
        }
      }
    }

    for (var i = 0; i < nn; i++) {
      if (i < low || i > high) {
        for (var j = i; j < nn; j++) {
          eigenVectors.set(i, j, hessenbergCache.get(i, j));
        }
      }
    }

    for (var j = nn - 1; j >= low; j--) {
      for (var i = low; i <= high; i++) {
        z = 0.0;
        for (var k = low; k <= math.min(j, high); k++) {
          z = z + eigenVectors.get(i, k) * hessenbergCache.get(k, j);
        }
        eigenVectors.set(i, j, z);
      }
    }
  }
}

/// Extension method on `List<List<double>>` with two shortcuts to read and
/// write the contents of a list of lists.
extension _EigenHelper on List<List<double>> {
  /// Reads the data at the given ([row]; [col]) position.
  double get(int row, int col) => this[row][col];

  /// Writes the given [value] in the ([row]; [col]) position.
  void set(int row, int col, double value) {
    this[row][col] = value;
  }
}
