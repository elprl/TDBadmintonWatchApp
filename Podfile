use_frameworks!
workspace 'Badminton'


def myPods
	#pod 'CorePlot', :git => 'https://github.com/core-plot/core-plot.git', :branch => 'release-2.1'
	#pod 'CorePlot', :git => 'https://github.com/core-plot/core-plot.git', :commit => '24f219e'
	pod 'CorePlot'

	pod 'JGProgressHUD'
	pod 'MHPrettyDate'
	pod 'DateTools'
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
end

target 'BadmintonUITests' do
	platform :ios, '11.0'
	project 'Badminton.xcodeproj'
	myPods
end

target 'Badminton WatchKit Extension' do
  platform :watchos, '4.0'
  project 'BadmintonWakt.xcodeproj'

end
