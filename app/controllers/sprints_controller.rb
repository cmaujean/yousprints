class SprintsController < ApplicationController

  def index
    respond_to do |format|
      format.html do
        @graph_data = Sprint.getSprintsInDateRange("this_week", current_user.id)
        render 'index'
      end
      format.json do 
        if ! params[:date_range].nil?
          sprints_info = Sprint.getSprintsInDateRange(params[:date_range], current_user.id)
          render :json => sprints_info
        end
      end
    end
  end
  
  def new
    @sprint = Sprint.new
    @note_sprint_dump = Note.new
    @note_sprint_reminders = Note.new
    @note_sprint_dump.note_type = NoteType.where(name: 'sprint_notes')[0]
    @note_sprint_reminders.note_type = NoteType.any_of({name: /reminder/})[0]
    #@notes = [@note_sprint_dump, @note_sprint_reminders]
    @notes = [@note_sprint_reminders]
    @notes.each do |note|
      @sprint.notes << note
    end
  end
  
  def create
    respond_to do |format|
      format.json do
        @sprint = Sprint.new(params[:sprint])
        current_user.sprints << @sprint
        render :json => @sprint
      end
    end
  end
  
  def update
    @sprint = current_user.sprints.find(params[:id])
    respond_to do |format|
      format.json do
        if ! params[:sub_processes].nil?
          sub_processes_hash = ActiveSupport::JSON.decode(params[:sub_processes])
          if params["reminder_notes"] != ""
            note_type = NoteType.where(name: "sprint_reminder_notes").first
            note = Note.new(content: params["reminder_notes"], note_type: note_type)
            @sprint.notes << note
          end
          @sprint.create_sub_processes_from_hash(sub_processes_hash)
        elsif ! params[:sprint][:duration].nil?
          @sprint.update_attributes(params[:sprint])  
        end
        render :json => @sprint
      end
      format.js do
        if ! params[:sprint][:interruptions].nil?
          @sprint.update_attributes(params[:sprint] )
        end
      end
      format.html do
        if ! params[:sprint][:percentage_complete].nil?
          @sprint.update_attributes(params[:sprint] )
          notice_text = "Your sprint has been successfully submitted."
          reminder_note_type = NoteType.where(name: 'sprint_reminder_notes').first.id
          remember_notes = @sprint.notes.where(note_type_id: reminder_note_type )
          if remember_notes.length > 0
            remember_note = remember_notes.first.content
            notice_text = notice_text + "<br/><br/>Reminder Notes:<br/> <div style='margin-left:15px'>#{remember_note}</div>"
          end
          redirect_to new_sprint_path, notice: notice_text
        end
      end
    end
  end     
  
end
