import time
import board
import busio
import digitalio
import adafruit_dht
import adafruit_tsl2561
import statistics
import json

# Initialize sensors
dht = adafruit_dht.DHT11(board.D24, use_pulseio=False)

i2c = busio.I2C(board.SCL, board.SDA)
tsl = adafruit_tsl2561.TSL2561(i2c)
tsl.enable = True
tsl.gain = 0
tsl.integration_time = 1

def collect_sensor_data():
	temps, luxes = [], []

	print("Collecting 10 readings from each sensor...")

	for i in range(10):
		try:
			# Read DHT11
			temp = dht.temperature
			if temp is not None: temps.append(temp)
		except RuntimeError:
			pass  # Ignore bad DHT reads

		# Read TSL2561
		lux = tsl.lux
		if lux is not None:
			luxes.append(lux)
		
		time.sleep(0.5)

	# Compute medians
	result = {
		"temperature_c": round(statistics.median(temps), 2) if temps else None,
		"lux": round(statistics.median(luxes), 2) if luxes else None
	}
	
	# Output to stream and .txt file
	overlay_text = f"Lux: {result['lux']} lx | Temp: {result['temperature_c']} C"
	with open("/tmp/stream_overlay.txt", "w") as f:
		f.write(overlay_text)
		
	with open("sensor_data.txt", "w") as f:
		for key, val in result.items():
			f.write(f"{key}={val}\n")
	
	return result

if __name__ == '__main__':
	print(json.dumps(collect_sensor_data(), indent=2))
