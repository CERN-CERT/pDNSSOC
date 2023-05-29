require_relative 'constants'
require 'fileutils'

module InputData
  include ConstantsData

  def get_groups()
    # Get a list of all files in the directory
    files = Dir.glob(File.join(PATH_ALERTS, RGX_FILE_REF))

    # Sort files by date extracted from the filename, newest first
    sorted_files = files.sort_by do |file|
      match = File.basename(file).match(RGX_FILE_TIME)
      match ? match[0] : ''
    end.reverse

    # Initialize groups as an empty array
    groups = []
    current_group = [] # Initialize current group as an empty array
    current_group_size = 0

    # Iterate through the sorted files
    sorted_files.each do |file|
      # Get the file size in bytes
      file_size = File.size(file)

      # Check if adding the file exceeds the group size limit
      if current_group_size + file_size > GROUP_SIZE  # Convert 500MB to bytes
        # Add the current group to the groups array
        groups << current_group

        # Create a new current group and reset current group size
        current_group = []
        current_group_size = 0
      end

      # Add the file to the current group
      current_group << file
      current_group_size += file_size
    end
    groups << current_group
    return groups 
  end
end

