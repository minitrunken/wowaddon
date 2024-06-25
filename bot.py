import pyautogui
import time
import mss
from PIL import Image
import keyboard
import win32gui

# Define abilities with their color and corresponding key
abilities = [
    (0xFF0000, "alt+1"),    # Mind Freeze - röd
    (0x00FF00, "shift+2"),  # Rune Tap - grön
    (0x0000FF, "shift+3"),  # Icebound Fortitude - blå
    (0x800080, "alt+3"),    # Vampiric Blood - lila
    (0xFFFF00, "alt+2"),    # Raise Dead - gul
    (0xFF00FF, "0"),        # Death Pact - magenta
    (0x00FFFF, "alt+5"),    # Horn of Winter - cyan
    (0x808080, "alt+4"),    # Bone Shield - grå
    (0x4C4C4C, "9"),        # Dancing Rune Weapon - mörkgrå
    (0xCCCCCC, "7"),        # Rune Strike - ljusgrå
    (0x333333, "1"),        # Icy Touch - grå
    (0x666666, "6"),        # Plague Strike - grå
    (0xFF8000, "4"),        # Blood Boil - orange
    (0x800000, "2"),        # Heart Strike - röd
    (0xE6E600, "8"),        # Pestilence - gul
    (0x1A1A1A, "3"),        # Death Strike - mörkgrå
    (0xB3B3B3, "5"),        # Death and Decay - ljusgrå
    (0xCC1ACC, "1"),        # OutBreak - lila
    (0x98FF98, "shift+1"),  # Death Grip - grön
    (0x808000, "6")         # Dark Command - olivgrön
]

def get_pixel_color(x, y):
    with mss.mss() as sct:
        monitor = {"top": y, "left": x, "width": 1, "height": 1}
        sct_img = sct.grab(monitor)
        img = Image.frombytes("RGB", sct_img.size, sct_img.rgb)
        color = img.getpixel((0, 0))
        return color

def color_match(pixel_color, target_color, tolerance=20):  # Reduced tolerance
    r, g, b = pixel_color
    target_r = (target_color >> 16) & 0xFF
    target_g = (target_color >> 8) & 0xFF
    target_b = target_color & 0xFF

    match = (abs(r - target_r) <= tolerance and
             abs(g - target_g) <= tolerance and
             abs(b - target_b) <= tolerance)
    return match

def use_ability(color, key, tolerance):
    for x in range(1880, 1960):  # Expanded range
        for y in range(20, 100):  # Expanded range
            pixel_color = get_pixel_color(x, y)
            print(f"Checking pixel color at ({x}, {y}): {pixel_color} against target {hex(color)}")  # Debugging line
            if color_match(pixel_color, color, tolerance):
                print(f"Ability detected: {hex(color)} at ({x}, {y}). Pixel color: {pixel_color}. Pressing {key}")
                pyautogui.hotkey(*key.split('+'))
                return True
    return False

def is_wow_active():
    active_window = win32gui.GetForegroundWindow()
    window_title = win32gui.GetWindowText(active_window)
    print(f"Active window title: {window_title}")
    return "World of Warcraft" in window_title

def main():
    print("Starting script. Press Ctrl+Q to exit.")
    was_active = False
    try:
        while True:
            if keyboard.is_pressed('ctrl+q'):
                print("Exiting program...")
                break
            
            wow_active = is_wow_active()
            
            if wow_active:
                if not was_active:
                    print("World of Warcraft is active. Running script...")
                    was_active = True
                
                # Check for abilities
                ability_used = False
                for color, key in abilities:
                    if use_ability(color, key, tolerance=20):
                        ability_used = True
                        break
                
                if not ability_used:
                    wrongway()
                    autotarget()
            else:
                if was_active:
                    print("World of Warcraft is not active. Waiting...")
                    was_active = False
                
                time.sleep(0.5)  # Wait longer to prevent continuous checking when not active
                
            time.sleep(0.1)  # Prevent CPU overuse
    except KeyboardInterrupt:
        print("Program interrupted manually.")
    finally:
        print("Cleaning up and exiting...")

def wrongway():
    print("Checking for wrong way...")
    for x in range(2273, 2325):
        for y in range(30, 85):
            pixel_color = get_pixel_color(x, y)
            if color_match(pixel_color, 0x00FF00, tolerance=20):
                print(f"Wrong way detected at ({x}, {y}). Correcting...")
                pyautogui.keyDown('a')
                time.sleep(0.5)
                pyautogui.keyUp('a')
                return
    print("Wrong way not detected")

def autotarget():
    print("Checking for auto target...")
    for x in range(33, 55):
        for y in range(1070, 1092):
            pixel_color = get_pixel_color(x, y)
            if color_match(pixel_color, 0xFD0000, tolerance=20):
                print(f"Target detected at ({x}, {y}). Pixel color: {pixel_color}. Pressing tab")
                pyautogui.press('tab')
                return
    print("Target not detected")

if __name__ == "__main__":
    main()
