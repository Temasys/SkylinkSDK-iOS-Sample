# SkylinkSDK-iOS-Sample

This is a sample application for [Skylink iOS SDK](http://skylink.io/ios/).

1. Clone the repository
2. pod install
3. Open SkylinkSample.xcworkspace or SampleAppSwift.xcworkspace
4. Get your app-key and secret from [Developer Console](https://developer.temasys.com.sg)

For Fabric users:
- At the SampleAppObjectiveC directory of this project, add a bash script named "fabric.sh".
- Make it executable by executing on the command line in it's directory:
chmod +x fabric.sh
- In fabric.sh, include the following line:
./Fabric.framework/run <Fabric API Key> <Fabric Build Secret>
- Replacing the the angle brackets and their contents with what they described.