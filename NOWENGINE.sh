# 显示主菜单
show_menu() {
    echo "now!text V2"
    echo ""
    echo "主菜单"
    echo "1. 新的游戏"
    echo "2. 继续游戏"
    echo "3. 删除进度"
    echo "4. 运行自定义游戏"
    echo "5. 退出"
    echo ""
}

# 运行游戏的核心函数（已重构）
run_game() {
    local level_file=$1
    if [ ! -f "$level_file" ]; then
        echo "错误：关卡文件 '$level_file' 不存在。"
        return 1
    fi

    local plot=""
    local -a choice_texts=()
    local -a choice_blocks=()

    # 将关卡文件一次性读入数组，便于处理
    mapfile -t lines < "$level_file"

    # 获取当前关卡的基础缩进层级
    local base_indent=0
    if [ ${#lines[@]} -gt 0 ]; then
        local first_line="${lines[0]}"
        while [[ "${first_line:base_indent:1}" == "-" ]]; do
            ((base_indent++))
        done
    fi

    # 遍历文件的每一行来解析当前场景
    for i in "${!lines[@]}"; do
        local line="${lines[i]}"
        # 跳过空行
        if [[ -z "$line" ]]; then continue; fi

        # 使用bash内建功能计算当前行的缩进，效率更高
        local indent=0
        while [[ "${line:indent:1}" == "-" ]]; do
            ((indent++))
        done

        # 只处理与基础缩进相同层级的剧情和选项
        if (( indent == base_indent )); then
            local content="${line:indent}" # 去掉缩进前缀
            local type="${content:0:1}"
            local text="${content:2}"

            if [[ "$type" == "P" || "$type" == "S" ]]; then
                # 这是剧情或对话，添加到 plot
                plot+="${text}\n"
            elif [[ "$type" == "B" ]]; then
                # 这是一个选项，B后面是编号和文本
                choice_texts+=("${content:3}")
                
                # 捕获此选项下方的所有内容作为一个新的“关卡块”
                local block=""
                for (( j=i+1; j<${#lines[@]}; j++ )); do
                    local sub_line="${lines[j]}"
                    local sub_indent=0
                    while [[ "${sub_line:sub_indent:1}" == "-" ]]; do
                        ((sub_indent++))
                    done

                    # 如果下一行的缩进更深，说明它是当前选项的一部分
                    if (( sub_indent > indent )); then
                        # 在保存时，去掉一级缩进
                        block+="${sub_line:1}\n"
                    else
                        # 缩进变浅或持平，说明这个选项的内容块结束了
                        break
                    fi
                done
                choice_blocks+=("$block")
            fi
        fi
    done

    # --- 游戏流程 ---

    # 显示剧情
    if [[ -n "$plot" ]]; then
        echo -e "$plot"
        read -p "按任意键继续..." -n1 -s
        echo ""
    fi

    # 如果没有选项（比如只是一段剧情通往下一关或结局）
    if (( ${#choice_texts[@]} == 0 )); then
        local last_line_content=$(echo -e "${lines[-1]}" | tr -d '[:space:]')
        local type="${last_line_content:base_indent:1}"
        local text="${last_line_content:base_indent+2}"
        
        if [[ "$type" == "N" ]]; then
            echo "$text" > ./levels/progress.cfg
            run_game "$text"
            return
        elif [[ "$type" == "E" ]]; then
            echo "游戏结束！"
            exit 0
        fi
        # 如果没有 N 或 E，视为分支结束
        return
    fi

    # 显示选项
    for i in "${!choice_texts[@]}"; do
        echo "$((i + 1)). ${choice_texts[$i]}"
    done

    # 获取玩家选择
    local user_choice
    while true; do
        read -p "请输入你的选择: " user_choice
        if [[ "$user_choice" =~ ^[1-9][0-9]*$ ]] && [ "$user_choice" -le "${#choice_texts[@]}" ]; then
            break
        else
            echo "无效的选择，请重新输入。"
        fi
    done

    # 处理选择
    local selected_index=$((user_choice - 1))
    local selected_block="${choice_blocks[selected_index]}"

    # 为选择的剧情块创建一个临时关卡文件
    local temp_level_file=$(mktemp ./levels/temp.XXXXXX)
    echo -e "$selected_block" > "$temp_level_file"
    
    # 保存进度并运行下一段剧情
    echo "$temp_level_file" > ./levels/progress.cfg
    run_game "$temp_level_file"
}

main() {

while true; do
    show_menu
    read -p "请输入你的选择: " choice

    case $choice in
        1)
            # 新的游戏
            # 先删除临时的旧关卡，如果有的话
            rm -f ./levels/temp.*
            echo "./levels/level1.ntl" > ./levels/progress.cfg
            run_game "./levels/level1.ntl"
            ;;
        2)
            # 继续游戏
            if [ -s "./levels/progress.cfg" ]; then
                level_to_continue=$(head -n 1 ./levels/progress.cfg)
                run_game "$level_to_continue"
            else
                echo "没有可继续的游戏进度。"
            fi
            ;;
        3)
            # 删除进度
            > ./levels/progress.cfg
            rm -f ./levels/temp.*
            echo "游戏进度已删除。"
            ;;
        4)
            # 运行自定义游戏
            read -p "请输入自定义关卡文件名 (例如: my_level.ntl): " custom_level
            if [ -f "./playerlevels/$custom_level" ]; then
                # 先删除临时的旧关卡
                rm -f ./levels/temp.*
                run_game "./playerlevels/$custom_level"
            else
                echo "错误：自定义关卡文件不存在。"
            fi
            ;;
        5)
            # 退出
            echo "再见！"
            exit 0
            ;;
        *)
            echo "无效的选择，请重新输入。"
            ;;
    esac
done

}

-CLEAR() {
clear
}


#启动参数：
-CLEAR