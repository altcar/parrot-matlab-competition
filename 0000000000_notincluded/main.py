
import serial
import numpy as np
import struct

# Configuration
SERIAL_PORT = 'COM11'  # The OTHER side of your virtual pair
BAUD_RATE = 115200
MASK_W = 160
MASK_H = 120
PACKED_SIZE = 600      # 19200 pixels / 32 bits
TOTAL_U32 = PACKED_SIZE + 1  # 600 mask elements + 1 centroid
BYTE_COUNT = TOTAL_U32 * 4   # 4 bytes per uint32

def unpack_mask(packed_data):
    """Converts 600 uint32s back into a 120x160 binary array."""
    # Create an empty boolean array for the mask
    mask = np.zeros(MASK_H * MASK_W, dtype=bool)
    
    for i in range(PACKED_SIZE):
        val = packed_data[i]
        for b in range(32):
            # Check if the b-th bit is set
            if (val & (1 << b)):
                mask[i * 32 + b] = True
    
    return mask.reshape((MASK_H, MASK_W))

try:
    ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
    print(f"Connected to {SERIAL_PORT}. Waiting for drone data...")

    while True:
        # 1. Wait until we have enough bytes for a full packet
        if ser.in_waiting >= BYTE_COUNT:
            raw_bytes = ser.read(BYTE_COUNT)
            
            # 2. Unpack the bytes into uint32 integers
            # 'I' is unsigned int (4 bytes), '<' is little-endian (Standard for MATLAB/Intel)
            data = struct.unpack(f'<{TOTAL_U32}I', raw_bytes)
            
            # 3. Separate packed mask and centroid
            packed_mask = data[:600]
            centroid_raw = data[600]
            
            # 4. Decipher values
            centroid = centroid_raw / 100.0  # Reverse the *100 scaling
            binary_image = unpack_mask(packed_mask)
            
            # 5. Output Results
            print(f"Centroid: {centroid:.2f} | Pixels Active: {np.sum(binary_image)}")
            
            # (Optional) If you want to see the image, you could use:
            import cv2
            cv2.imshow('Drone View', binary_image.astype(np.uint8) * 255)
            cv2.waitKey(1)

except KeyboardInterrupt:
    print("\nClosing connection.")
    ser.close()
except Exception as e:
    print(f"Error: {e}")
