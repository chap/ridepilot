module DocumentAssociableController

  # Set @parent instance variable
  def self.included(including_class)
    including_class.before_action :load_associable_resource
    including_class.before_action :init_documents_present
  end

  # Sets the including controller's resource to a generic @parent instance variable,
  # for use in views
  def load_associable_resource
    @parent = self.model_instance
  end

  # Returns the including controller's resource model instance
  def model_instance
    self.instance_variable_get('@' + self.class.controller_name.classify.underscore)
  end
  
  # Builds new associated documents from params
  def build_new_documents(params)
    return params unless params[:documents_attributes].present?
    
    # Build new documents as appropriate
    params[:documents_attributes].each do |i, doc|
      unless doc[:id].present?
        if doc[:document].present? && doc[:_destroy].to_i.zero?
          @documents_present = true      
          model_instance.build_document(
            document: doc[:document], 
            description: doc[:description]
          )
        end
        params[:documents_attributes].delete(i)
      end
    end
            
    return params
  end
  
  # returns a list of documents attributes for safe params
  def documents_attributes
    [:id, :document, :description, :_destroy]
  end
  
  # Sends a flash reminder if documents were present
  def show_documents_reminder
    flash[:reminder] = "You must re-attach your documents." if @documents_present
  end
  
  private
  
  def init_documents_present
    @documents_present = false
  end
  
end
