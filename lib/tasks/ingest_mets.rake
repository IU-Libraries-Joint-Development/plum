desc "Ingest one or more METS files"
task ingest_mets: :environment do
  user = User.find_by_user_key( ENV['USER'] ) if ENV['USER']
  user = User.all.select{ |u| u.admin? }.first unless user

  collections = (ENV['COLLECTIONS'] || "").split(" ")

  logger = Logger.new(STDOUT)
  IngestMETSJob.logger = logger
  logger.info "ingesting mets files from: #{ARGV[1]}"
  logger.info "ingesting as: #{user.user_key} (override with USER=foo)"
  abort "usage: rake ingest_mets /path/to/mets/files" unless ARGV[1] && Dir.exist?(ARGV[1])
  Dir["#{ARGV[1]}/**/*.mets"].each do |file|
    IngestMETSJob.perform_now(file, user, collections)
  end
end
