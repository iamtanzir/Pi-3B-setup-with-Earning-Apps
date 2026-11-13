"""Render banner.svg to PNG(s) with Playwright (file:// allowed here)."""
import pathlib
from playwright.sync_api import sync_playwright

repo = pathlib.Path(__file__).resolve().parent.parent
svg_uri = (repo / "assets" / "banner.svg").as_uri()

with sync_playwright() as p:
    b = p.chromium.launch()

    # 1) README banner — exact SVG canvas size, 2x for crispness
    page = b.new_page(viewport={"width": 1280, "height": 400}, device_scale_factor=2)
    page.goto(svg_uri)
    page.wait_for_timeout(400)
    page.screenshot(path=str(repo / "assets" / "banner.png"),
                    clip={"x": 0, "y": 0, "width": 1280, "height": 400})

    # 2) GitHub social-preview card — 1280x640 (2:1), banner centred on matching bg
    social_html = f"""<!doctype html><html><head><style>
      html,body{{margin:0;height:100%;background:#0b1220;}}
      body{{display:flex;align-items:center;justify-content:center;}}
      img{{width:1152px;height:360px;}}
    </style></head><body><img src="{svg_uri}"></body></html>"""
    (repo / "assets" / "_social.html").write_text(social_html, encoding="utf-8")
    page2 = b.new_page(viewport={"width": 1280, "height": 640}, device_scale_factor=2)
    page2.goto((repo / "assets" / "_social.html").as_uri())
    page2.wait_for_timeout(400)
    page2.screenshot(path=str(repo / "assets" / "banner-social.png"))

    b.close()

(repo / "assets" / "_social.html").unlink()
print("banner.png and banner-social.png written")
