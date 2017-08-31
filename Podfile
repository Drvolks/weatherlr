target 'watch' do
  platform :watchos, "4.0"
  
  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for watch
  pod 'WeatherFramework', :path => "./WeatherFramework/"
end

target 'watch Extension' do
  platform :watchos, "4.0"
  
  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for watch Extension
  pod 'WeatherFramework', :path => "./WeatherFramework/"
end

target 'weatherlr' do
  platform :ios, '11.0'

  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for weatherlr
  pod 'WeatherFramework', :path => "./WeatherFramework/"

  target 'weatherlrTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'weatherlrUITests' do
    inherit! :search_paths
    # Pods for testing
  end
end

target 'weatherlrFree' do
  platform :ios, '11.0'
  
  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for weatherlrFree
  pod 'WeatherFramework', :path => "./WeatherFramework/"
  
  # Google ads
  pod 'Firebase/Core'
  pod 'Firebase/AdMob'
end
