use_frameworks!
workspace 'Badminton'

def myPods
	pod 'CorePlot'

	pod 'JGProgressHUD'
	pod 'MHPrettyDate'
	pod 'DateTools'
    pod 'Viperit'
end

def testingPods
    pod 'Quick'
    pod 'Nimble'
end

target 'Badminton' do
	platform :ios, '11.0'
	project 'Badminton.xcodeproj'
	myPods
end

target 'BadmintonTests' do
	platform :ios, '11.0'
	project 'Badminton.xcodeproj'
	myPods
    testingPods
end

target 'BadmintonUITests' do
	platform :ios, '11.0'
	project 'Badminton.xcodeproj'
	myPods
    testingPods
end

target 'Badminton WatchKit Extension' do
  platform :watchos, '4.0'
  project 'BadmintonWakt.xcodeproj'

end
