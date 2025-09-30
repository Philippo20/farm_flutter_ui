import paho.mqtt.client as mqtt
import time
import random

# MQTT broker configuration
MQTT_BROKER = "134.209.22.156"  # Change to your broker IP/hostname
MQTT_PORT = 1883
MQTT_USERNAME = "FarmEstatesMqtt"  # ← Replace with your actual username
MQTT_PASSWORD = "Farm2021"  # ← Replace with your actual password
MQTT_KEEPALIVE = 60

# Global connection state
is_connected = False

# Callback: on connect
def on_connect(client, userdata, flags, rc):
    global is_connected
    if rc == 0:
        print("✅ Connected to MQTT Broker")
        is_connected = True
    else:
        print(f"❌ Failed to connect, return code {rc}")

# Callback: on disconnect
def on_disconnect(client, userdata, rc):
    global is_connected
    print("⚠️ Disconnected from MQTT Broker")
    is_connected = False

# Initialize client and set credentials
client = mqtt.Client()
client.username_pw_set(MQTT_USERNAME, MQTT_PASSWORD)
client.on_connect = on_connect
client.on_disconnect = on_disconnect

client.connect(MQTT_BROKER, MQTT_PORT, MQTT_KEEPALIVE)
client.loop_start()  # Start network loop in background

# Value generation rules
def generate_values():
    return {
        "setCurrent": str(random.randint(15, 20)),
        "Temp2": str(random.randint(15, 20)),
        "waterTempreture": str(random.randint(15, 20)),
        "Distance": str(random.randint(0, 100)),

        "humdity": str(random.randint(50, 70)),
        "humidity2": str(random.randint(50, 70)),

        "ec-sensor": f"{random.uniform(1.0, 1.2):.2f}",
        "ph-sensor": f"{random.uniform(5.5, 6.5):.1f}",

        "tds-sensor": str(random.randint(300, 800)),
        "c02-sensor": str(random.randint(400, 1200)),

        "grid_powersupply": str(random.randint(100, 3000)),
        "grid_current": str(random.randint(1, 20)),
        "grid_Voltage": str(random.randint(210, 250)),
        "grid_energy": f"{random.uniform(0, 100):.1f}",
        "grid_bill": str(random.randint(1, 500)),

        "solar_power": f"{random.uniform(0, 1000):.1f}",
        "solar_powersupply": f"{random.uniform(0, 1000):.1f}",

        "battery_power": str(random.randint(20, 100)),
        "battery_charge": str(random.randint(20, 100)),

        "Rack1_lights": random.choice(["OFF", "OFF"]),
        "Rack2_lights": random.choice(["OFF", "OFF"]),
        "Rack3_lights": random.choice(["ON", "OFF"]),

        "WaterPumpState": random.choice(["ON", "OFF"]),
        "AirPumpState": random.choice(["ON", "OFF"]),
        "NutPumpState": random.choice(["ON", "OFF"]),
        "PhUpRelayState": random.choice(["ON", "OFF"]),
        "PhDownRelayState": random.choice(["ON", "OFF"]),
        "AirConditionState": random.choice(["ON", "OFF"]),
    }

# Initial values and timer
current_values = generate_values()
last_update = time.time()

# Main loop
try:
    while True:
        now = time.time()

        # Regenerate data every 1 minute
        if now - last_update >= 60:
            current_values = generate_values()
            last_update = now

        # Publish if connected
        if is_connected:
            for topic, value in current_values.items():
                result = client.publish(topic, value)
                status = result[0]
                if status == 0:
                    print(f"📤 Published to `{topic}`: {value}")
                else:
                    print(f"⚠️ Failed to send `{topic}`")
        else:
            print("⏳ Waiting for MQTT connection...")

        time.sleep(2)

except KeyboardInterrupt:
    print("🛑 Script stopped by user.")
    client.loop_stop()
    client.disconnect()
