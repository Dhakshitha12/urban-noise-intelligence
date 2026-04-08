import math

class AmbientNoiseAnalyzer:
    """
    An Object-Oriented Library for analyzing and classifying urban noise levels.
    Demonstrates encapsulation, static thresholds, and programmatic calculations.
    """

    # Static thresholds
    HIGH_THRESHOLD = 80
    MODERATE_THRESHOLD = 50

    def __init__(self, amplitude):
        """
        Constructor initializes the analyzer with raw amplitude data.
        """
        self._amplitude = amplitude
        self._decibel = None
        self._classification = None

    def calculate_decibel(self):
        """
        Transforms raw amplitude into an decibel float metric (dB).
        Formula: 20 * log10(amplitude)
        """
        if self._amplitude <= 0:
            raise ValueError("Amplitude must be greater than zero.")
        self._decibel = 20 * math.log10(self._amplitude)
        return self._decibel

    def classify_noise(self):
        """
        Classifies the exact risk factor of the calculated decibel level.
        """
        if self._decibel is None:
            self.calculate_decibel()

        if self._decibel > self.HIGH_THRESHOLD:
            self._classification = "High Noise"
        elif self._decibel > self.MODERATE_THRESHOLD:
            self._classification = "Moderate Noise"
        else:
            self._classification = "Low Noise"
            
        return self._classification

    def get_full_report(self):
        """
        Returns a dictionary representing the generated noise intelligence report.
        """
        return {
            'decibel': round(self.calculate_decibel(), 2),
            'noise_type': self.classify_noise(),
            'engine': 'AmbientNoiseAnalyzer_v1.0'
        }
