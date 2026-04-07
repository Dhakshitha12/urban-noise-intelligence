class NoiseAnalyzer:

    def calculate_decibel(self, amplitude):
        return amplitude * 20


    def classify_noise(self, decibel):

        if decibel > 80:
            return "High Noise"

        elif decibel > 50:
            return "Moderate Noise"

        else:
            return "Low Noise"