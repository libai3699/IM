# 换图标
.fvm/flutter_sdk/bin/flutter pub run flutter_launcher_icons

# 编译 iOS release 版本
echo "开始编译 iOS release 版本..."
.fvm/flutter_sdk/bin/flutter build ios --release

if [ $? -ne 0 ]; then
    echo "编译失败，请检查错误信息"
    exit 1
fi

# 生成 IPA
echo "生成 IPA 文件..."
mkdir Payload 2>/dev/null
cp -rf build/ios/iphoneos/Runner.app Payload/ 2>/dev/null

if [ ! -d "Payload/Runner.app" ]; then
    echo "错误：找不到 Runner.app 文件"
    exit 1
fi

rm -f Runner.ipa
zip -qr Runner.ipa Payload

if [ $? -ne 0 ]; then
    echo "IPA 生成失败"
    exit 1
fi

# 清理
rm -rf Payload

echo "IPA 文件已成功生成: $PWD/Runner.ipa"