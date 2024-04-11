class TextError < ApplicationRecord

  def self.remove_duplicates
    ActiveRecord::Base.transaction do
      connection.execute <<-SQL
        DELETE FROM text_errors WHERE id NOT IN (SELECT MIN(id) FROM text_errors GROUP BY line);
      SQL
    end
  rescue StandardError => e
    Rails.logger.error "Error removing duplicates - #{e.message}"
  end


end
