
desc 'clean merged data bags'
task :clean do
  FileUtils.rm_rf "#{$WORKSPACE_SETTINGS[:paths][:vagrant_state_dir]}/data_bags", :secure => true
end

desc "Open browser to local Jenkins"
task :open_browser_to_jenkins do
  url = "https://#{$WORKSPACE_SETTINGS[:machine_report][:jenkins][:provider][:network][:ip_address]}"

  shell_script(
    %^
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --ignore-certificate-errors  #{url}
osascript -e 'tell application "Google Chrome" to activate'
^,
    live_stream: nil
  )
end