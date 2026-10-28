#!/usr/bin/env python3
"""
يعدّل android/app/build.gradle.kts بعد توليده تلقائيًا من flutter create:

1) يرفع minSdk إلى 24 (أعلى متطلب بين المكتبات الحالية: image_picker=24،
   mobile_scanner=23).
2) يضيف إعداد توقيع إصدار (release signing) يُستخدم فقط لو وجد ملف
   android/key.properties. لو الملف غير موجود (الحالة الافتراضية بدون
   أسرار GitHub) يفضل البناء بتوقيع debug بالضبط زي ما كان قبل كده، فالسكربت
   ده آمن سواء المستخدم ضبط التوقيع أو لأ.

يُستدعى من الـ workflow هكذا: python3 android_overlay/patch_build_gradle.py android/app/build.gradle.kts
"""
import re
import sys
import pathlib

MARKER = "cobraKeystoreProperties"


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: patch_build_gradle.py <path-to-build.gradle.kts>", file=sys.stderr)
        return 1
    path = pathlib.Path(sys.argv[1])
    if not path.exists():
        print(f"ERROR: file not found: {path}", file=sys.stderr)
        return 1
    src = path.read_text(encoding="utf-8")
    original = src

    # 1) minSdk -------------------------------------------------------
    if re.search(r"minSdk\s*=\s*flutter\.minSdkVersion", src):
        src = re.sub(r"minSdk\s*=\s*flutter\.minSdkVersion", "minSdk = 24", src, count=1)
        print("minSdk: patched to 24 (was flutter.minSdkVersion)")
    elif re.search(r"minSdk\s*=\s*\d+", src):
        src = re.sub(r"minSdk\s*=\s*\d+", "minSdk = 24", src, count=1)
        print("minSdk: patched to 24 (overrode fixed value)")
    else:
        print("WARNING: minSdk line not found, skipping minSdk patch", file=sys.stderr)

    # 2) Properties loader (مرة واحدة فقط أعلى الملف) ------------------
    if MARKER not in src:
        loader = (
            "import java.util.Properties\n"
            "import java.io.FileInputStream\n\n"
            f"val {MARKER} = Properties()\n"
            f"val {MARKER}File = rootProject.file(\"key.properties\")\n"
            f"if ({MARKER}File.exists()) {{\n"
            f"    {MARKER}.load(FileInputStream({MARKER}File))\n"
            "}\n\n"
        )
        m = re.search(r"^\}\s*\n", src[src.index("plugins"):], re.MULTILINE)
        if m:
            insert_at = src.index("plugins") + m.end()
            src = src[:insert_at] + "\n" + loader + src[insert_at:]
        else:
            src = loader + src
        print("signing: added key.properties loader")

    # 3) signingConfigs block داخل android { ---------------------------
    if "signingConfigs {" not in src:
        signing_block = (
            "    signingConfigs {\n"
            "        create(\"release\") {\n"
            f"            if ({MARKER}File.exists()) {{\n"
            f"                keyAlias = {MARKER}[\"keyAlias\"] as String\n"
            f"                keyPassword = {MARKER}[\"keyPassword\"] as String\n"
            f"                storeFile = file({MARKER}[\"storeFile\"] as String)\n"
            f"                storePassword = {MARKER}[\"storePassword\"] as String\n"
            "            }\n"
            "        }\n"
            "    }\n\n"
        )
        m = re.search(r"android\s*\{\n", src)
        if m:
            src = src[: m.end()] + signing_block + src[m.end():]
            print("signing: inserted signingConfigs block")
        else:
            print("ERROR: 'android {' block not found, aborting", file=sys.stderr)
            return 1

    # 4) ربط buildTypes.release بالتوقيع المناسب ------------------------
    cond = (
        f'if ({MARKER}File.exists()) signingConfigs.getByName("release") '
        'else signingConfigs.getByName("debug")'
    )
    pattern_named = re.compile(
        r'(named\("release"\)\s*\{[^}]*?signingConfig\s*=\s*)signingConfigs\.getByName\("debug"\)',
        re.DOTALL,
    )
    pattern_plain = re.compile(
        r'(\brelease\s*\{[^}]*?signingConfig\s*=\s*)signingConfigs\.getByName\("debug"\)',
        re.DOTALL,
    )
    if pattern_named.search(src):
        src = pattern_named.sub(lambda m: m.group(1) + cond, src, count=1)
        print("signing: wired named(\"release\") signingConfig")
    elif pattern_plain.search(src):
        src = pattern_plain.sub(lambda m: m.group(1) + cond, src, count=1)
        print("signing: wired release { } signingConfig")
    elif "signingConfig =" not in src:
        print(
            "WARNING: no 'signingConfig = signingConfigs.getByName(\"debug\")' line found; "
            "release build will keep whatever default Flutter generated (usually debug signing).",
            file=sys.stderr,
        )

    if src != original:
        path.write_text(src, encoding="utf-8")
        print(f"patched: {path}")
    else:
        print(f"no changes applied to {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
