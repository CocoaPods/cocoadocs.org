require 'active_support/core_ext/string/strip'
require 'timeout'

class SourceDownloader
  include HashInit
  attr_accessor :spec, :download_location, :overwrite

  def download_pod_source_files
    version = $force_branch ? $force_branch : @spec.version
    puts "\n Looking at #{@spec.name} #{version} \n".bold.blue

    if Dir.exist?(@download_location)
      if @overwrite
        command "rm -rf #{@download_location}"
      else
        return
      end
    end

    source = @spec.source
    if $force_branch
      if source[:git]
        source[:tag] = $force_branch
        source[:commit] = nil if source.key? :commit
      end
    end

    # Git 2.3+ support no interactive modes if this is set, see #293
    ENV['GIT_TERMINAL_PROMPT'] = '0'

    # this is 5 minutes, which may not be long enough for things like cocos2d.
    # but that can be dealt with if it's an issue.

    Timeout::timeout(300) {
      downloader = Pod::Downloader.for_target(@download_location, source)
      downloader.download
      run_prepare_command
    }

  end

  # Runs the prepare command bash script of the spec.
  #
  # @note   Unsets the `CDPATH` env variable before running the
  #         shell script to avoid issues with relative paths
  #         (issue #1694).

  # @note   Copied from CocoaPods/CocoaPods
  #
  # @return [void]
  #
  def run_prepare_command
    return unless @spec.root.prepare_command
    vputs ' > Running prepare command'
    Dir.chdir(@download_location) do
      ENV.delete('CDPATH')
      prepare_command = @spec.root.prepare_command.strip_heredoc.chomp
      full_command = "\nset -e\n" + prepare_command
      `#{full_command}`
    end
  end
end
