from noise_analyzer.analyzer import NoiseAnalyzer

analyzer = NoiseAnalyzer()

decibel = analyzer.calculate_decibel(4)
noise_type = analyzer.classify_noise(decibel)

print("Decibel:", decibel)
print("Noise Type:", noise_type)