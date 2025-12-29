module Admin
  class CustomerImportsController < BaseController
    def new
      @import_history = import_history
    end

    def create
      unless params[:file].present?
        redirect_to new_admin_customer_import_path, alert: 'ファイルを選択してください。'
        return
      end

      file = params[:file]

      unless valid_file_format?(file)
        redirect_to new_admin_customer_import_path, alert: 'CSV形式のファイルを選択してください。'
        return
      end

      # バックグラウンドジョブで実行
      CustomerImportJob.perform_later(
        file.read,
        file.original_filename,
        current_user.id
      )

      redirect_to new_admin_customer_import_path,
                  notice: 'インポートを開始しました。完了後にメールで通知します。'
    end

    private

    def valid_file_format?(file)
      File.extname(file.original_filename).downcase.in?(['.csv', '.xlsx', '.xls'])
    end

    def import_history
      if defined?(ImportLog)
        ImportLog.where(import_type: 'customers')
                 .order(created_at: :desc)
                 .limit(10)
      else
        []
      end
    end
  end
end
