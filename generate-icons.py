#!/usr/bin/env python3
"""
Icon Generator for EtherealOS
Creates simple colored circle icons with emoji for each app
"""
import os

def create_svg_icon(emoji, color, name, output_dir):
    """Create a simple SVG icon with emoji"""
    svg = f'''<?xml version="1.0" encoding="UTF-8"?>
<svg width="64" height="64" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:{color};stop-opacity:1" />
      <stop offset="100%" style="stop-color:{color};stop-opacity:0.7" />
    </linearGradient>
  </defs>
  <circle cx="32" cy="32" r="30" fill="url(#grad)"/>
  <text x="32" y="42" font-size="32" text-anchor="middle" fill="white">{emoji}</text>
</svg>'''
    filepath = os.path.join(output_dir, f"{name}.svg")
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(svg)
    return filepath

def generate_all_icons():
    """Generate all app icons"""
    output_dir = os.path.expanduser("~/.local/share/icons/ethereal")
    os.makedirs(output_dir, exist_ok=True)
    
    icons = [
        ("🛍️", "#7ed7ff", "ethereal-store"),
        ("🦊", "#ff6b6b", "ethereal-browser"),
        ("⚡", "#ffd93d", "ethereal-optimizer"),
        ("🚀", "#6bcf7f", "ethereal-game"),
        ("🖥️", "#a8d8ea", "ethereal-hardware"),
        ("🛠️", "#aa96da", "ethereal-repair"),
        ("👋", "#fcbad3", "ethereal-welcome"),
        ("🪐", "#7ed7ff", "ethereal-update"),
    ]
    
    for emoji, color, name in icons:
        create_svg_icon(emoji, color, name, output_dir)
        print(f"Created: {name}.svg")
    
    print(f"\nIcons created in: {output_dir}")
    return output_dir

if __name__ == "__main__":
    generate_all_icons()
