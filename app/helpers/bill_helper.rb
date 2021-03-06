module BillHelper

  def bill_type_name(bill_type)
    case bill_type
    when 'hres' then '<div>Resolutions</div> <span>House of Representatives</span>'
    when 'hr' then '<div>Bills</div> <span>House of Representatives</span>'
    when 'hjres' then '<div>Joint Resolutions</div> <span>House of Representatives</span>'
    when 'hconres' then '<div>Concurrent Resolution</div> <span>House of Representatives</span>'
    when 's' then '<div>Bills</div> <span>Senate</span>'
    when 'sres' then '<div>Resolutions</div> <span>Senate</span>'
    when 'sjres' then '<div>Joint Resolutions</div> <span>Senate</span>'
    when 'sconres' then '<div>Concurrent Resolution</div> <span>Senate</span>'
    end
  end

  def bill_type_page_title(bill_type)
    case bill_type
    when 'hres' then 'Resolutions: House of Representatives'
    when 'hr' then 'Bills: House of Representatives'
    when 'hjres' then 'Joint Resolutions: House of Representatives'
    when 'hconres' then 'Concurrent Resolution: House of Representatives'
    when 's' then 'Bills: Senate'
    when 'sres' then 'Resolutions: Senate'
    when 'sjres' then 'Joint Resolutions: Senate'
    when 'sconres' then 'Concurrent Resolution: Senate'
    end
  end

  def bill_name(bill_type, number)
    abbr = UnitedStates::Bills.abbreviation_for bill_type
    "#{abbr}#{number}"
  end

  def title
    "#{@bill.typenumber}: #{@bill.title_official}"
  end

  def em_title
    "#{@bill.typenumber}: <em>#{@bill.title_official}</em>"
  end

  def official_title
    @bill.title_official.blank? ? "#{@bill.typenumber}" : "#{@bill.title_official}"
  end

  def bill_titles_html
    out = ""
    @bill.bill_titles.map do |bt|

      out += "<li><strong>#{bt.title_type.capitalize}:</strong> " +
             " #{bt.title}" + (bt.as != '' ? "<em> as #{bt.as}.</em>" : ".") + "</li>"
    end

    out.html_safe
  end

  def display_bill_titles
    "<a href='#' id='bill_title_link' onclick='change_vis_text(\"bill_titles\", " +
      "\"bill_title_link\", \"...all bill titles\", \"...hide bill titles\");return false'>" +
      "...all bill titles</a>".html_safe
  end

  def bill_related_bills_html
    return '' unless @bill.related_bills.size > 0
    render :partial => 'related_bills_list', :object => @bill.related_bills
  end

  def display_related_bills
    return "No related bills" unless @bill.related_bills.size > 0

    %Q{<a href="#" id="bill_related_link" onclick="change_vis_text('bill_related_bills', 'bill_related_link', 'Show related bills', 'Hide related bills');return false">Show related bills</a>}
  end

	def bill_related_list
		bill_limit = 6
		text = partial_list(@bill.related_bills, :title_full_common, bill_limit,
		"#{@bill.related_bills.size - bill_limit} more", "bill_related_extra",
		"bill_related_more", "show", "bill", true, 75)
	end

  def bill_subject_list
    # item_limit is the initial number of items to show
    item_limit = 2
    text = partial_list(@bill.subjects, :term, item_limit,
      "#{@bill.subjects.size - item_limit} more", "bill_subjects_extra",
      "bill_subjects_more", "show", "issue", false, false)
    # Show nothing if the list is empty
    text == "" ? '' : "#{text}"
  end

  def bill_summary_with_more
    return "" if @bill.summary.blank?

    summary_no_html = @bill.summary.gsub(/<\/?[^>]*>/, "")
    summary_no_html.gsub!(/"/, "\\\"")
    summary_no_html.gsub!(/'/, "&apos;")

    summary = @bill.summary
    summary.gsub!(/THOMAS\sHome[\w\s\|]*/,"")
		summary.gsub!(/(\(\d+\))/) { |d| '<br /><strong>' + $1 + '</strong>'}
		summary.gsub!(/(\(Sec\.\s\d+\))/) { |s| '<br /><br /><h4>' + $1 + '</h4>'}
    if summary
      if summary.length <= 300
        out = summary
      else
        summary.gsub!(/"/, "\\\"")
        summary.gsub!(/'/, "&apos;")

        out = "<script type='text/javascript'>
        $j().ready(function() {
        	$j('#bill_summary_extra').jqm({trigger: 'a.summary_trigger'});
        });
        </script>"

        out += summary_no_html[0..290] + %Q{<span id="bill_summary_extra" class='jqmWindow scrolling'><div class="ie"><a href="#" class="jqmClose"><span>Close</span></a></div><h3>Official Summary</h3>#{summary}<br /><br /></span>...<a href="#" class="summary_trigger more"><strong>Read the Rest</strong></a>}
      end
    end
  end

  def co_sponsor_list
   	text = "<ul class='lined_list'>"
		#@bill.co_sponsors[0..@bill.co_sponsors.size].each do |c|
		@bill.bill_cosponsors.includes(:person).order("people.lastname").each do |c|
		  text += "<li>"
		  text += link_to "<span class='small#{' withdrawn' unless c.date_withdrawn.blank?}'>#{c.person.name}</span>".html_safe, :controller => 'people', :action => 'show', :id => c.person
		  text += "<br /><span class='small'>Added #{c.date_added.strftime('%B %d, %Y')}</span>" unless c.date_added.blank?
		  text += "<br /><span class='small'>Wthdrawn #{c.date_withdrawn.strftime('%B %d, %Y')}</span>" unless c.date_withdrawn.blank?
		  text += "</li>"
		end
    text += "</ul>"
		return text
  end

	def issue_list(start,stop)
		text = "<ul class='lined_list'>"
		@bill.subjects[start..stop].each do |s|
		  text += "<li>"
		  text += link_to s.term, :controller => 'issues', :action => 'show', :id => s
		  text += "</li>"
		end
    text += "</ul>"
		return text
	end

	def committee_list(start,stop)
		text = "<ul class='lined_list'>"
		@bill.committees[start..stop].each do |c|
		  text += "<li>"
		  text += link_to c.proper_name, :controller => 'committee', :action => 'show', :id => c
		  text += "</li>"
		end
    text += "</ul>"
		return text
	end

  def bill_full_text_link
    #"http://thomas.loc.gov/cgi-bin/query/z?c#{@bill.session}:#{@bill.typenumber}:"
    url_for :controller => 'bill', :action => 'text', :id => @bill.ident
  end

  def bill_active
    '<div class="bill_active">Active</div>' if @bill.last_action.datetime > Time.now.last_month
  end

  def limited_summary
    if @bill.summary.length < 300
      "#{@bill.summary}"
    else
      "#{@bill.summary.slice(0..299)} ... <a "
    end
  end

  def action
    "Latest action: <span class='bill_action'>#{@bill.action}</span>."
  end

  def sponsor
    "Sponsored by <span class='person_name'>#{@bill.sponsor.name}</span>."
  end


	def bill_status_table(bill = @bill)
		status_hash = bill.bill_status_hash
		text = "<table border='0' cellpadding='0' cellspacing='0' id='bill-status'>"
		text += "<tr>"
    pending = false
		status_hash['steps'].each do |s|
    current = ''
      if s.has_value?('Bill Becomes Law') || s.has_value?('Bill Is Law') || s.has_value?('Resolution Passed')
        text += "<td class='divide #{s['class']}'><span>&nbsp;</span></td>"
        text += "<td id='bill-law' class='#{s['class']}'></td>"
      else
        if pending == false
          if s['result'] == 'Pending'
            pending = true
            current = ' current'
          end
        end
        text += %Q{<td class="divide #{s['class']}#{current}"><span>&nbsp;</span></td><td class="#{s['class']}">}
        unless s['roll_id'].blank?
          text += %Q{<a href="/roll_call/show/#{s['roll_id']}">}
        end
        text += %Q{<table class="info" cellpadding="0" cellspacing="0"><tr><td>#{s['text'].gsub(/\s/, "<br/>")}</td></tr>}
        text += "</table>"
        unless s['roll_id'].blank?
          text += "</a>"
        end
        text += '</td>'
			  if s.has_value?('Failed')
			    text += '<td class="close"></td>'
			  end
  		end
  	end
    text += '</tr></table><br />
        <table border="0" cellpadding="0" cellspacing="0" id="bill-status-dates">
        <tr>'
    pending = false
		status_hash['steps'].each do |s|
    current = ''
      if s.has_value?('Bill Becomes Law') || s.has_value?('Bill Is Law') || s.has_value?('Resolution Passed')
        text += %Q{<td class="divide #{s['class']}"><span>&nbsp;</span></td>}
      else
        if pending == false
          if s['result'] == 'Pending'
            pending = true
            current = ' current'
          end
        end
        text += %Q{<td class="divide #{s['class']}#{current}"><span class="hump">&nbsp;</span></td><td class="#{s['class']}">
          <table class="info" cellpadding="0" cellspacing="0"><tr><td><strong>#{s['date'] ? s['date'].strftime('%m/%d/%y') : '<span class="empty">&nbsp;</span>'}</strong></td></tr></table></td>}
			  if s.has_value?('Failed')
			    text += '<td class="close"></td>'
			  end
  		end
  	end
    text += "</tr></table><br />"

    return text
  end

	def other_bills_tracking
		out = ""
		num = @tracking_suggestions.length
		limit = 5
		@tracking_suggestions[0..4].each do |t|
			out += '<table cellspacing="0" cellpadding="0">
              <tr><td style="padding-right:5px;">' +
          + link_to(truncate(t[:bill].title_full_common, :length => 30), bill_url(t[:bill]))
          + "</td><td>["
          + link_to(t[:trackers], {:controller => 'friends', :action => 'tracking_bill', :id => t[:bill].ident})
          + "]</td></tr>"
		      + "</table>"
		end
		more = num - limit
		if more > 0
			out += '<table id="more_tracking_suggestions" cellspacing="0" cellpadding="0" style="display:none;">'
			@tracking_suggestions[5..num].each do |t|
					out += '<tr><td style="padding-right:5px;">'
					    + link_to(truncate(t[:bill].title_full_common, :length => 30), bill_url(t[:bill]))
					    + "</td>\n"
					    + "<td>["
					    + link_to(t[:trackers], {:controller => 'friends', :action => 'tracking_bill', :id => t[:bill].ident})
					    + "]</td></tr>\n"
			end
			out += "</table>\n"
			out += toggler("more_tracking_suggestions", "#{more} more bills", "Hide Others Tracking", "arrow", "arrow-hide")
		end
	return out
	end

  def until_preposition (text)
    sentence = text.gsub(/\n|\r/, ' ').split(/\.\s*/).first
    prepositions = [ 'about', 'below', 'in', 'spite', 'of', 'regarding',
                     'above', 'beneath', 'instead', 'of', 'since', 'according',
                     'to', 'beside', 'into', 'through', 'across', 'between',
                     'like', 'throughout', 'after', 'beyond', 'near', 'to',
                     'against', 'but', 'of', 'toward', 'along', 'by', 'off',
                     'under', 'amid', 'concerning', 'on', 'underneath',
                     'among', 'down', 'on', 'account', 'of', 'until', 'around',
                     'during', 'onto', 'up', 'at', 'except', 'out', 'upon',
                     'atop', 'for', 'out', 'of', 'with', 'because', 'of',
                     'from', 'outside', 'within', 'before', 'in', 'over',
                     'without', 'behind', 'inside', 'past' ]
    tokens = sentence.split(/(\w+(?:[.,']\w+)*|-|\S+)/).select{|t| t.length > 0}
    stop_ix = tokens.to_enum.with_index.to_a.index{|t, ix| ix > 7 and prepositions.include?(t)}
    if stop_ix
      tokens.slice(0, stop_ix).join('')
    else
      sentence
    end
  end 
end
