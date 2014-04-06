module PaginationHelper
    class JqueryMobilePaginateLinkRenderer < WillPaginate::ActionView::LinkRenderer
      def pagination
        items = [] # NOTE: ignore the :page_links option
        items.unshift :previous_page
        items.push :next_page
      end

      protected

      def html_container(html)
        tag :div, html, class: 'ui-grid-a'
      end

      def previous_or_next_page(page, text, classname)
        div_attr = {}
        link_attr = {:'data-role' => 'button'}

        unless page
          link_attr[:class] = 'ui-disabled'
        end

        case classname
        when 'previous_page'
          link_attr[:'data-icon'] = 'arrow-l'
          div_attr[:class] = 'ui-block-a'
        when 'next_page'
          link_attr[:'data-icon'] = 'arrow-l'
          link_attr[:'data-iconpos'] = 'right'
          div_attr[:class] = 'ui-block-b'
        end
        tag :div, link(text, page || '#', link_attr), div_attr
      end
    end
end