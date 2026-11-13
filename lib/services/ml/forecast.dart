class ForecastResult {
  final String modelType; // linear_regression | random_forest | tier_average
  final String modelVersion;
  final List<double> values;
  final String confidence; // LOW/MEDIUM/HIGH
  final double? validationMetric;
  ForecastResult({required this.modelType, required this.modelVersion, required this.values, required this.confidence, this.validationMetric});
}

class MlForecast {
  /// Forecast next [horizon] months from monthly series (chronological).
  static ForecastResult forecast(List<double> series, {required int horizon, required String cityTier}) {
    // Cold start
    if (series.length < 3) {
      // tier-based average fallback
      final avg = series.isEmpty ? _tierAverage(cityTier) : series.reduce((a,b)=>a+b)/series.length;
      final vals = List<double>.filled(horizon, avg);
      return ForecastResult(modelType: 'tier_average', modelVersion: 'v1-coldstart', values: vals, confidence: 'LOW', validationMetric: null);
    }

    // Linear regression on index
    final lr = _linearRegressionForecast(series, horizon);
    // Random forest (simplified: bagging of stumps on lag1,lag2)
    final rf = _randomForestForecast(series, horizon);

    // Validation: hold out last point
    final holdout = series.last;
    final lrPred = _linearRegressionPredict(series.sublist(0, series.length-1), 1).first;
    final rfPred = _randomForestPredict(series.sublist(0, series.length-1), 1).first;
    final lrErr = (lrPred - holdout).abs();
    final rfErr = (rfPred - holdout).abs();

    if (lrErr <= rfErr) {
      return ForecastResult(modelType: 'linear_regression', modelVersion: 'v1', values: lr, confidence: 'MEDIUM', validationMetric: lrErr);
    } else {
      return ForecastResult(modelType: 'random_forest', modelVersion: 'v1', values: rf, confidence: 'MEDIUM', validationMetric: rfErr);
    }
  }

  static double _tierAverage(String tier) {
    switch (tier) {
      case 'Tier 1': return 25000;
      case 'Tier 2': return 15000;
      case 'Tier 3': return 9000;
      default: return 15000;
    }
  }

  static List<double> _linearRegressionForecast(List<double> series, int horizon) {
    final n = series.length;
    // fit y = a + b*x
    double sx=0, sy=0, sxx=0, sxy=0;
    for (int i=0;i<n;i++){ sx+=i; sy+=series[i]; sxx+=i*i; sxy+=i*series[i]; }
    final denom = n*sxx - sx*sx;
    final b = denom==0?0:(n*sxy - sx*sy)/denom;
    final a = (sy - b*sx)/n;
    final out = <double>[];
    for (int h=1; h<=horizon; h++) {
      out.add((a + b*(n-1+h)).clamp(0, double.infinity).toDouble());
    }
    return out;
  }

  static List<double> _linearRegressionPredict(List<double> series, int horizon) {
    return _linearRegressionForecast(series, horizon);
  }

  static List<double> _randomForestForecast(List<double> series, int horizon) {
    // Use lag1, lag2 averages with small variance; simple stump ensemble
    final preds = _randomForestPredict(series, horizon);
    return preds;
  }

  static List<double> _randomForestPredict(List<double> series, int horizon) {
    // Build training samples: x=[lag1,lag2], y=next
    final samples = <List<double>>[];
    final labels = <double>[];
    for (int i=2;i<series.length;i++){
      samples.add([series[i-1], series[i-2]]);
      labels.add(series[i]);
    }
    // Ensemble of 5 stumps: predict average of neighbors within threshold
    final out = <double>[];
    var last = series.last;
    var prev = series.length>=2?series[series.length-2]:series.last;
    for (int h=0; h<horizon; h++) {
      // find similar samples
      final neighbors = <double>[];
      for (int i=0;i<samples.length;i++){
        final d = (samples[i][0]-last).abs() + (samples[i][1]-prev).abs();
        if (d < (last*0.5+1)) neighbors.add(labels[i]);
      }
      double pred;
      if (neighbors.isEmpty) {
        pred = series.reduce((a,b)=>a+b)/series.length;
      } else {
        pred = neighbors.reduce((a,b)=>a+b)/neighbors.length;
      }
      if (pred < 0) pred = 0;
      out.add(pred);
      prev = last;
      last = pred;
    }
    return out;
  }
}
