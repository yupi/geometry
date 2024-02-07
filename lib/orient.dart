// ignore_for_file: non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers
// ignore_for_file: constant_identifier_names

import 'dart:typed_data';

const epsilon = 1.1102230246251565e-16;
const resulterrbound = (3 + 8 * epsilon) * epsilon;
const ccwerrboundA = (3 + 16 * epsilon) * epsilon;
const ccwerrboundB = (2 + 12 * epsilon) * epsilon;
const ccwerrboundC = (9 + 64 * epsilon) * epsilon * epsilon;

double orient2d(Float64x2 a, Float64x2 b, Float64x2 c) {
  final detleft = (a.y - c.y)*(b.x - c.x);
  final detright = (a.x - c.x)*(b.y - c.y);
  final det = detleft - detright;

  final detsum = (detleft + detright).abs();
  if (det.abs() >= ccwerrboundA*detsum) return det.sign;

  return -orient2dAdapt(a.x, a.y, b.x, b.y, c.x, c.y, detsum).sign;
}

double orient2dFast(Float64x2 a, Float64x2 b, Float64x2 c) {
  return ((a.y - c.y)*(b.x - c.x) - (a.x - c.x)*(b.y - c.y)).sign;
}

final B = Float64List(4);
final C1 = Float64List(8);
final C2 = Float64List(12);
final D = Float64List(16);
final u = Float64List(4);

double orient2dAdapt(
  double ax, double ay,
  double bx, double by,
  double cx, double cy,
  double detsum
) {
  final acx = ax - cx;
  final bcx = bx - cx;
  final acy = ay - cy;
  final bcy = by - cy;

  crossProduct(acx, bcx, acy, bcy, B);

  var det = estimate(4, B);
  var errbound = ccwerrboundB * detsum;
  if (det >= errbound || -det >= errbound) {
    return det;
  }

  final acxtail = twoDiffTail(ax, cx, acx);
  final bcxtail = twoDiffTail(bx, cx, bcx);
  final acytail = twoDiffTail(ay, cy, acy);
  final bcytail = twoDiffTail(by, cy, bcy);

  if (acxtail == 0 && acytail == 0 && bcxtail == 0 && bcytail == 0) {
    return det;
  }

  errbound = ccwerrboundC * detsum + resulterrbound * det.abs();
  det += (acx * bcytail + bcy * acxtail) - (acy * bcxtail + bcx * acytail);
  if (det >= errbound || -det >= errbound) {
    return det;
  }

  crossProduct(acxtail, bcx, acytail, bcy, u);
  final C1len = sum(4, B, 4, u, C1);

  crossProduct(acx, bcxtail, acy, bcytail, u);
  final C2len = sum(C1len, C1, 4, u, C2);

  crossProduct(acxtail, bcxtail, acytail, bcytail, u);
  final Dlen = sum(C2len, C2, 4, u, D);

  return D[Dlen - 1];
}

const splitter = 134217729;

(double, double) fastTwoSum(a, b) {
  final x = a + b;
  final bv = x - a;
  final av = x - bv;
  final br = b - bv;
  final ar = a - av;
  return (x, ar + br);
}

(double, double) twoSum(a, b) {
  final x = a + b;
  final bvirt = x - a;
  final y = a - (x - bvirt) + (b - bvirt);
  return (x, y);
}

(double, double) twoDiff(double a, double b) {
  final x = a - b;
  return (x, twoDiffTail(a, b, x));
}

double twoDiffTail(a, b, x) {
  final bvirt = a - x;
  return a - (x + bvirt) + (bvirt - b);
}

(double, double) twoProduct(double a, double b) {
  final x = a * b;

  final c = splitter * a;
  final abig = c - a;
  final ahi = c - abig;
  final alo = a - ahi;

  final d = splitter * b;
  final bbig = d - b;
  final bhi = d - bbig;
  final blo = b - bhi;

  final err = x - (ahi * bhi) - (alo * bhi) - (ahi * blo);
  final y = alo * blo - err;

  return (x, y);
}

(double, double, double) twoOneDiff(double a1, double a0, double b) {
  final (_i, x0) = twoDiff(a0, b);
  final (x2, x1) = twoSum(a1, _i);
  return (x2, x1, x0);
}

void twoTwoDiff(double a1, double a0, double b1, double b0, List<double> result) {
  assert(result.length >= 4);

  final (_j, _0, x0) = twoOneDiff(a1, a0, b0);
  final (x3, x2, x1) = twoOneDiff(_j, _0, b1);
  result[0] = x0;
  result[1] = x1;
  result[2] = x2;
  result[3] = x3;
}

void crossProduct(double a, double b, double c, double d, List<double> result) {
  assert(result.length >= 4);

  final (s1, s0) = twoProduct(a, d);
  final (t1, t0) = twoProduct(c, b);
  twoTwoDiff(s1, s0, t1, t0, result);
}

int sum(int elen, List<double> e, int flen, List<double> f, List<double> h) {
  double Q;
  double Qnew;
  double hh;
  double enow = e[0];
  double fnow = f[0];
  int eindex = 0;
  int findex = 0;

  if ((fnow > enow) == (fnow > -enow)) {
    Q = enow;
    enow = e[++eindex];
  } else {
    Q = fnow;
    fnow = f[++findex];
  }

  int hindex = 0;
  if (eindex < elen && findex < flen) {
    if ((fnow > enow) == (fnow > -enow)) {
      (Qnew, hh) = fastTwoSum(enow, Q);
      enow = e[++eindex];
    } else {
      (Qnew, hh) = fastTwoSum(fnow, Q);
      fnow = f[++findex];
    }
    Q = Qnew;
    if (hh != 0) {
      h[hindex++] = hh;
    }
    while (eindex < elen && findex < flen) {
      if ((fnow > enow) == (fnow > -enow)) {
        (Qnew, hh) = twoSum(Q, enow);
        if (++eindex < elen) enow = e[eindex];
      } else {
        (Qnew, hh) = twoSum(Q, fnow);
        if (++findex < flen) fnow = f[findex];
      }
      Q = Qnew;
      if (hh != 0) {
        h[hindex++] = hh;
      }
    }
  }

  while (eindex < elen) {
    (Qnew, hh) = twoSum(Q, enow);
    if (++eindex < elen) enow = e[eindex];
    Q = Qnew;
    if (hh != 0) {
      h[hindex++] = hh;
    }
  }

  while (findex < flen) {
    (Qnew, hh) = twoSum(Q, fnow);
    if (++findex < flen) fnow = f[findex];
    Q = Qnew;
    if (hh != 0) {
      h[hindex++] = hh;
    }
  }

  if (Q != 0 || hindex == 0) {
    h[hindex++] = Q;
  }
  return hindex;
}

double estimate(elen, e) {
  double Q = e[0];
  for (var i = 1; i < elen; i++) {
    Q += e[i];
  }
  return Q;
}
