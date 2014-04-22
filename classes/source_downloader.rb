class SourceDownloader
  include HashInit
  attr_accessor :spec, :download_location, :overwrite

  def download_pod_source_files
    puts "\n ----------------------"
    puts "\n Looking at #{@spec.name} #{@spec.version} \n".bold.blue

    cache_path = File.join($active_folder, 'download_cache')

    if Dir.exist?(@download_location)
      if @overwrite
        command "rm -rf #{@download_location}"
      else
        return
      end
    end

    downloader = Pod::Downloader.for_target(@download_location, @spec.source)
    downloader.cache_root = cache_path
    downloader.download
  end
end

