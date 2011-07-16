require 'open3'

module GraphvizHelper

  include InfoHelper
  
  def dot_line(name, options = {})
    line = name.to_s + " "
    unless options.empty?
      optstrs = options.map {|key, val|
        "#{key} = #{val}"
      }
      line += " [#{optstrs.join(', ')}]"
    end
    line += ';'
  end

  def dot_line_connect(a, b, isboth=false)
    opts = {}
    opts['dir'] = 'both'	if isboth
    dot_line("#{a} -> #{b}", opts)
  end
  
  def dot_digraph(name, &blk)
    str = "digraph #{name} {"
    str += yield 
    str += "}"
  end

  def quote(str)
    "\"#{str}\""
  end


  def create_dot_statuses(statuses, uses)
    opt = {}
    str = ""
    statuses.each {|sts|
      next 	unless uses.include?(sts.id)
      opt.clear
      if (sts.is_default?)
        opt['style'] = 'filled'
        opt['fillcolor'] = quote 'yellow'
      elsif (sts.is_closed?)
        opt['style'] = 'filled'
        opt['fillcolor'] = quote '#D3D3D3'
      end
      opt['label'] = quote sts.name
      str += dot_line(sts.position, opt)
    }
    str
  end


  def create_dot_workflow(statuses, wf, subwf)
    str = ""
    uses = []
    for stspos in 0..(statuses.size-1)
      break	if (stspos+1 == statuses.size-1)
      for nstspos in (stspos+1)..(statuses.size-1)
        if (workflow_flowable?(subwf, statuses[stspos], statuses[nstspos]) or
              workflow_flowable?(wf, statuses[stspos], statuses[nstspos]))
          str += dot_line_connect(statuses[stspos].position, statuses[nstspos].position,
                                  (workflow_flowable?(subwf, statuses[nstspos], statuses[stspos]) or
                                     workflow_flowable?(wf, statuses[nstspos], statuses[stspos])))
          uses << statuses[stspos].position
          uses << statuses[nstspos].position
        end
      end
    end
    [str, uses.uniq]
  end

#   digraph sample {
# node [shape = box, fontname="ＭＳ ゴシック"];
# 新規 [style = filled, fillcolor = "yellow"];
# 終了 [style = filled, fillcolor = "gray"];
# 新規 -> 進行中;
# 新規 -> フィードバック;
# 新規 -> 解決;
# 新規 -> 終了;
# 進行中 -> フィードバック [dir = both];
# 進行中 -> 解決 [dir = both];
# 進行中 -> 終了;
# フィードバック -> 解決 [dir = both];
# フィードバック -> 終了;
# 解決 -> 終了;
# }
  def create_dot_digraph_workflow(graphname, statuses, wf, subwf)
    dot_digraph(quote graphname) {
      str = "ranksep = 0.3;"
      opt = {'shape' => 'box', 'margin' => '0.05'}
#       unless (Setting.plugin_redmine_information['dot_fontname'].blank?)
#         opt['fontname'] = Setting.plugin_redmine_information['dot_fontname']
#       end
      str += dot_line('node', opt)
      struses = create_dot_workflow(statuses, wf, subwf)
      str += create_dot_statuses(statuses, struses.last)
      str += struses.first
    }
  end


  def exec_dot(src)
    dest = ""
    errstr = ""
    reststr = ""
    bgnptn = /^<svg/
    endptn = /^<\/svg>/
    errptn = /^Error/i
    warningptn = /^\(dot(\.exe)?:\d+\)/i
    begin
      IO.popen("dot -Tsvg 2>&1", 'r+') {|io|
        io.puts src
        io.close_write
        while (str = io.gets)
          if (errptn =~ str)
            errstr << str
          elsif (warningptn =~ str)
            errstr << str
          elsif (bgnptn)
            if (bgnptn =~ str)
              dest += str
              bgnptn = nil
            else
              reststr << str
            end
          elsif (!bgnptn and endptn)
            dest += str
            endptn = nil	if (endptn =~ str)
          else
            reststr << str
          end
        end
      }
    rescue => evar
      errstr << l(:text_err_dot) + "\n"
      errstr << evar.to_s
    end
    if (dest.empty? or !$?.exited? or $?.exitstatus != 0)
      errstr = l(:text_err_dot) + "\n" + errstr
      errstr << reststr
    end
    [dest, errstr]
  end
  
  def create_workflow_chart(graphname, statuses, wf, subwf)
    results = exec_dot(create_dot_digraph_workflow(graphname, statuses, wf, subwf))
    str = results.first
    unless (results.last.blank?)
      str += "<div class='nodata'> #{simple_format(results.last)}</div>"
    end
    str
  end
  
end
