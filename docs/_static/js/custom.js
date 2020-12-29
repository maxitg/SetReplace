$(function () {
    const iconDown = "▼";
    const iconUp = "▲";

    $(".cpp .function > dd > dl").hide();

    $(".cpp.function > dt").each(function(index) {
        if($(this).next("dd").has("dl").length > 0) {
            $(this).children("br:last-of-type").before("<span class=\"dropdown-icon icon-down\">" + iconDown + "</span>");
        }
    });

    $(".cpp .function").click((event) => {
        $(event.currentTarget).children("dd").children("dl").toggle();
        $(event.currentTarget).find(".dropdown-icon").toggleClass(["icon-down", "icon-up"]);
        $(event.currentTarget).find(".dropdown-icon").text(function(i, t) {
            return t === iconDown ? iconUp : iconDown;
        });
    });
});