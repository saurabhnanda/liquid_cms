module Cms
  class Page < ActiveRecord::Base
    set_table_name 'cms_pages'

    attr_accessible :name, :slug, :content, :layout_page_id, :published, :root, :updated_by

    NAME_REGEX = /^[^\/][a-zA-Z0-9_\-\.]+$/

    belongs_to :layout_page, :class_name => self.to_s
    has_many :content_pages, :class_name => self.to_s, :foreign_key => 'layout_page_id', :dependent => :nullify, :order => 'name ASC'

    before_validation :clean_data
    before_save :verify_single_root

    validates_presence_of :content
#    validates_presence_of :slug, :message => "can't be blank for a published page", :if => proc{|page| page.published?}
    validates_format_of :name, :with => NAME_REGEX
    validates_uniqueness_of :name, :scope => (Cms.context_class ? :context_id : nil), :case_sensitive => false
    validates_uniqueness_of :slug, :scope => (Cms.context_class ? :context_id : nil), :case_sensitive => false, :allow_blank => true

    validates_each :slug do |record,attr,value|
      record.errors.add attr, "is reserved and can't be used for this page" if record.reserved_slug?
    end
    validates_each :slug, :published, :root do |record,attr,value|
      record.errors.add attr, "can't be set for a layout page" if value.present? && record.is_layout_page? 
    end

    named_scope :published, :conditions => {:published => true}
    named_scope :unpublished, :conditions => {:published => false}
    named_scope :layouts, :conditions => {:is_layout_page => true}
    named_scope :ordered, :order => 'is_layout_page DESC, name ASC'

    def to_s
      name
    end

    def reserved_slug?
      return false if self.slug.blank?

      begin
        # reserved paths
        return true if self.slug =~ /\A\/(stylesheets|scripts|images)\b/

        path_options = ActionController::Routing::Routes.recognize_path(slug, {:method => :get})
        # if the :url option is nil, then one of the existing routes matched the slug
        return true if path_options[:url].nil?
 
        # if "root path" of any of the existing routes match the "root path" of requested url, then the slug is reserved
        ActionController::Routing::Routes.routes.any? do |r|
          r.segments.collect{|s| s.to_s}.reject{|s| s == '/'}.first == path_options[:url].first
        end
      rescue ActionController::RoutingError
        false
      end
    end

    def rendered_content(controller)
      render_options = {} #{:filters => [CmsFilters, AppFilters]}
      common_assigns = {'params' => ParamsDrop.new((controller.params || {}).except(:controller, :action)), 'site_url' => controller.request.protocol + controller.request.raw_host_with_port}

      context_obj = Cms::Context.new(Cms.context_class ? context : nil)

      # render the current page
      page = self
      template = Liquid::Template.parse(page.content)
      template.registers[:context] = context_obj
      template.registers[:controller] = controller
      content = template.render(common_assigns, render_options)
      common_assigns.update(template.instance_assigns)

      # and then render any layout files of the current page
      while page.layout_page do
        page = page.layout_page
        template = Liquid::Template.parse(page.content)
        template.registers[:context] = context_obj
        content = template.render({'content_for_layout' => content}.merge(common_assigns), render_options)
        common_assigns.update(template.instance_assigns)
      end

      return content
    end

    def content_type
      Cms::Editable.content_type name
    end 

    def url
      case content_type
      when 'text/css'
        "/cms/stylesheets/#{name}"
      when 'text/javascript'
        "/cms/javascripts/#{name}"
      else
        slug = read_attribute(:slug)
        slug.present? ? slug : "/#{name}"
      end
    end

    def content=(text)
      write_attribute :content, text
      self.is_layout_page = !(text =~ /\{\{\s?content_for_layout\s?\}\}/).blank?
    end

  protected
    def clean_data
      if slug.present?
        # remove leading and trailing slashes (will catch multiple /'s on each end and remove them)
        self.slug.gsub!(/^\/*/,'').gsub!(/\/*$/,'') if self.slug.length > 1
        # add a leading /
        self.slug = '/'+self.slug
      end
    end

    def verify_single_root
      # if this page is being set as root, remove root for an existing page if found
      if root?
        home = Cms.context_class ? context.pages.root : self.class.first(:conditions => {:root => true})
        home.update_attribute :root, false if home && home != self
      end
    end
  end
end
